/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A service class that provides methods for interacting with
 * reports via the Analytics API.
 */
public class ReportService {
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
     * unique values from a given column in a given report.  This class will
     * iterate over every row in the given report.  To work around a limitation
     * in the Analytics API that a report run will only return the first 2,000
     * rows, the column being iterated over is expected to be a filterable and
     * sortable column.  This requirement comes from the technique of
     * paginating report results 2,000 records at a time by adding a sort to
     * the report and then filtering the report to exclude records from
     * previous "pages" of the report.  This will only return unique values
     * from the given column, meaning that if a value has already been returned
     * by this iterator then that value will be skipped next time.
     */
    public class ReportRowValueIterableIterator implements Iterator<Object>, Iterable<Object> {
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
         * @description The value of the last row processed.  This value is
         * used to filter results to retrieve the next "page"
         */
        private Object lastRowValue;

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
        public ReportRowValueIterableIterator(Id reportId, String columnName) {
            this.reportId = reportId;
            this.columnName = columnName;
        }

        /**
         * @description Implementation of iterator() from Iterable interface
         * @return Iterator<Object>
         */
        public Iterator<Object> iterator() {
            return new IteratorFilterUnique(this);
        }

        /**
         * @description Implementation of hasNext() from Iterator interface.
         * Returns true if there is another row in the report available.
         *
         * @return Boolean
         */
        public Boolean hasNext() {
            if (!hasRunReport) {
                runReport();
            }
            return currentPageRowIterator.hasNext() || !hasAllData;
        }

        /**
         * @description Implementation of next() from Iterator interface.
         * Returns the value from the specified column from the next available
         * report result detail row.
         *
         * @return Object
         */
        public Object next() {
            if (!hasRunReport || !currentPageRowIterator.hasNext()) {
                runReport();
            }
            Reports.ReportDetailRow row = currentPageRowIterator.next();
            lastRowValue = row.getDataCells().get(0).getValue();
            return lastRowValue;
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
                (String) lastRowValue
            );
            hasAllData = results.getAllData();
            Reports.ReportFactWithDetails facts = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
            currentPageRowIterator = facts.getRows().iterator();
        }
    }

    private class IteratorFilterUnique implements Iterator<Object> {
        private Iterator<Object> iterator;
        private Set<Object> seenObjects = new Set<Object>();
        private Boolean hasNext;
        private Object next;

        public IteratorFilterUnique(Iterator<Object> iterator) {
            this.iterator = iterator;
        }

        public Boolean hasNext() {
            if (null != hasNext) return hasNext;

            while (iterator.hasNext()) {
                next = iterator.next();
                if (!seenObjects.contains(next)) {
                    seenObjects.add(next);
                    hasNext = true;
                    return hasNext;
                }
            }
            hasNext = false;
            return hasNext;
        }

        public Object next() {
            hasNext = null;
            return next;
        }
    }
}