/*
    Copyright (c) 2015 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A service class that provides methods for interacting with
 * reports via the Analytics API.
 */
public class ReportService implements CampaignList.ReportService {
    /**
     * @description Retrieve the labels and ids of columns of type ID_TYPE from
     * the given report.  Returns a Map<String, String> where the column id is
     * the key and the label is the value.
     *
     * @param reportId The id of the report to find columns
     * @return Map<String, String>
     */
    public Map<String, String> getIdColumns(Id reportId) {
        Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport(reportId).getReportExtendedMetadata();
        Map<String, Reports.DetailColumn> reportColumns = metadata.getDetailColumnInfo();

        Map<String, String> idColumns = new Map<String, String>();

        for (Reports.DetailColumn column : reportColumns.values()) {
            if (Reports.ColumnDataType.ID_DATA == column.getDataType()) {
                idColumns.put(
                    column.getName(),
                    column.getLabel()
                );
            }
        }

        return idColumns;
    }

    /**
     * @description Runs a report and returns the results.  The given
     * indexColumn is the name of a column that can be used for sorting the
     * report for pagination, such that the values in this column can be used
     * to filter the report to exclude previously processed results.  The given
     * pageIndex value is an index into the report results corresponding to the
     * last row processed, and is used to filter out results from the report
     * run that have already been processed.  This is a technique to work
     * around the limitation that only the first 2,000 rows of a report's
     * results can be obtained through the Analytics API at a time.
     *
     * @param reportId The id of the report to run
     * @param indexColumn The name of the column to use for "indexing" (i.e., sorting and filtering) the report
     * @param pageIndex The value to use to determine where ReportResults processing last left off.  If null, the report is processed from the "beginning"
     * @return Reports.ReportResults
     */
    private static Reports.ReportResults getReportResults(Id reportId, String indexColumn, String pageIndex) {
        Reports.ReportMetadata metadata = Reports.ReportManager.describeReport(reportId).getReportMetadata();

        metadata.setReportFormat(Reports.ReportFormat.TABULAR);

        metadata.setDetailColumns(
            new List<String>{indexColumn}
        );

        Reports.SortColumn sortColumn = new Reports.SortColumn();
        sortColumn.setSortColumn(indexColumn);
        sortColumn.setSortOrder(Reports.ColumnSortOrder.ASCENDING);
        metadata.setSortBy(new List<Reports.SortColumn>{sortColumn});

        if (null != pageIndex) {
            List<Reports.ReportFilter> reportFilters = metadata.getReportFilters();
            reportFilters.add(new Reports.ReportFilter(
                indexColumn,
                'greaterThan',
                pageIndex
            ));
            metadata.setReportFilters(reportFilters);
        }

        Reports.ReportResults results = Reports.ReportManager.runReport(
            reportId,
            metadata,
            true
        );

        return results;
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description A custom Iterator that can be used to iterate over the
     * unique ids from a given column in a given report.  This class will
     * iterate over every row in the given report.  To work around a limitation
     * in the Analytics API that a report run will only return the first 2,000
     * rows, the column being iterated over is expected to be a filterable and
     * sortable column.  This requirement comes from the technique of
     * paginating report results 2,000 records at a time by adding a sort to
     * the report and then filtering the report to exclude records from
     * previous "pages" of the report.  This will only return unique ids
     * from the given column, meaning that if a value has already been returned
     * by this iterator then that value will be skipped next time.
     */
    public class ReportRowIdIterableIterator implements Iterator<Id>, Iterable<Id> {
        /** @description The id of the report to iterate over */
        @TestVisible
        private Id reportId;

        /**
         * @description The name of the column in the report to return values
         * from and use for indexing
         */
        @TestVisible
        private String columnName;

        /**
         * @description The id of the last row processed.  This id is
         * used to filter results to retrieve the next "page"
         */
        private Id lastRowId;

        /**
         * @description True if the last report run is the last page of
         * results.  False if there are more pages of data to be retrieved
         */
        private Boolean hasAllData;

        /**
         * @description The Iterator returned by List<Reports.ReportDetailRow>
         * returned by the ReportResults object.  This keeps track of the
         * current row being iterated over in the current page of results.
         */
        private Iterator<Reports.ReportDetailRow> currentPageRowIterator;

        /**
         * @description True if the report has been run at least once.  False,
         * otherwise.
         */
        private Boolean hasRunReport = false;

        /**
         * @description Construct a ReportRowValueIterableIterator for
         * iterating over the values from the given column name in the given
         * report
         *
         * @param reportId The id of the report to iterate over
         * @param columnName The name of the column to retrieve values from in the report
         */
        public ReportRowIdIterableIterator(Id reportId, String columnName) {
            this.reportId = reportId;
            this.columnName = columnName;
        }

        /**
         * @description Implementation of iterator() from Iterable interface
         * @return Iterator<Id>
         */
        public Iterator<Id> iterator() {
            return new IteratorMonotonicIncreasingIdFilter(this);
        }

        /**
         * @description Implementation of hasNext() from Iterator interface.
         * Returns true if there is another row in the report available.
         *
         * @return Boolean
         */
        public Boolean hasNext() {
            if (!hasRunReport || (!currentPageRowIterator.hasNext() && !hasAllData)) {
                runReport();
            }
            return currentPageRowIterator.hasNext();
        }

        /**
         * @description Implementation of next() from Iterator interface.
         * Returns the id from the specified column from the next available
         * report result detail row.
         *
         * @return Id
         */
        public Id next() {
            if (!hasNext()) {
                return null;
            }
            Reports.ReportDetailRow row = currentPageRowIterator.next();
            lastRowId = (Id) row.getDataCells().get(0).getValue();
            return lastRowId;
        }

        /**
         * @description Run the report to retrieve the next page (or the first
         * page if the report hasn't been run yet), and prepare the class state
         * for iterating over the new page's result rows.
         *
         * @return void
         */
        private void runReport() {
            hasRunReport = true;
            Reports.ReportResults results = ReportService.getReportResults(
                reportId,
                columnName,
                (String) lastRowId
            );
            hasAllData = results.getAllData();
            Reports.ReportFactWithDetails facts = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
            currentPageRowIterator = facts.getRows().iterator();
        }
    }

    /*
     * @author Salesforce.org
     * @group CampaignTools
     * @description This Iterator will return ids retrieved from
     * Iterator only if they are strictly greater than the previously returned id.
     */
    @TestVisible
    private class IteratorMonotonicIncreasingIdFilter implements Iterator<Id> {
        private Iterator<Id> iterator;
        private Id lastSeenId;
        private Boolean hasNext;
        private Id next;

        /*
         * @description Constructor
         * @param iterator The Iterator that is to be filtered for unique items
        */
        public IteratorMonotonicIncreasingIdFilter(Iterator<Id> iterator) {
            this.iterator = iterator;
        }

        /*
         * @description Implementation of hasNext() from Iterator interface.
         * Returns true if there is another value available from the filtered
         * iterator that is strictly greater than the most recently returned id.
         *
         * @return Boolean
         */
        public Boolean hasNext() {
            if (null != hasNext) return hasNext;

            while (iterator.hasNext()) {
                next = (Id) iterator.next();
                if (next > lastSeenId) {
                    hasNext = true;
                    return hasNext;
                }
            }
            hasNext = false;
            return hasNext;
        }

        /*
         * @description Implementation of next() from Iterator interface.
         * Returns the next value from the filtered iterator, ensuring that
         * only unique values are returned.
         *
         * @return Object
         */
        public Id next() {
            hasNext = null;
            return next;
        }
    }
}