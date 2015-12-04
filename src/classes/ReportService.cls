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
     * to filter the report to exclude previously processed results.  This is a
     * technique to work around the limitation that only the first 2,000 rows
     * of a report's results can be obtained through the Analytics API at a
     * time.
     *
     * @param reportId The id of the report to run
     * @param indexColumn The name of the column to use for "indexing" (i.e., sorting and filtering) the report
     * @return Reports.ReportResults
     */
    public static Reports.ReportResults getReportResults(Id reportId, String indexColumn) {
        return getReportResults(reportId, indexColumn, null);
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
    public static Reports.ReportResults getReportResults(Id reportId, String indexColumn, String pageIndex) {
        Reports.ReportMetadata metadata = new Reports.ReportMetadata();

        Reports.SortColumn sortColumn = new Reports.SortColumn();
        sortColumn.setSortColumn(indexColumn);
        sortColumn.setSortOrder(Reports.ColumnSortOrder.ASCENDING);
        metadata.setSortBy(new List<Reports.SortColumn>{sortColumn});

        if (null != pageIndex) {
            Reports.ReportFilter reportFilter = new Reports.ReportFilter(
                indexColumn,
                'greaterThan',
                pageIndex
            );
            metadata.setReportFilters(
                new List<Reports.ReportFilter>{reportFilter}
            );
        }

        Reports.ReportResults results = Reports.ReportManager.runReport(
            reportId,
            metadata,
            true
        );

        return results;
    }

    /**
     * @description Given a report id and the API name of a column in that
     * report, this method determines the integer column offset of that column
     * in the ReportResults ReportDetailRows.  If the column can not be found
     * in the report, this method throws a NoSuchColumnException.
     *
     * @param reportId The id of the report the column belongs to
     * @param columnName The API name of a column in that report
     * @return Integer
     */
    public static Integer getColumnOffsetByName(Id reportId, String columnName) {
        Reports.ReportMetadata metadata = Reports.ReportManager.describeReport(reportId).getReportMetadata();

        List<String> columns = metadata.getDetailColumns();

        for (Integer i=0; i < columns.size(); i++) {
            if (columnName == columns.get(i)) {
                return i;
            }
        }

        throw new NoSuchColumnException(
            'The column named ' + columnName + ' was not found in report ' + reportId
        );
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description A custom Iterator that can be used to iterate over the
     * values from a given column in a given report.  This class will iterate
     * over every row in the given report.  To work around a limitation in the
     * Analytics API that a report run will only return the first 2,000 rows,
     * the column being iterated over is expected to be a filterable and
     * sortable column.  This requirement comes from the technique of
     * paginating report results 2,000 records at a time by adding a sort to
     * the report and then filtering the report to exclude records from
     * previous "pages" of the report.  This implies that the column contain
     * unique values over the report rows so that filtering on the column will
     * not lead to missed records that fall "in between" the report pages.
     */
    public class ReportRowValueIterableIterator implements Iterator<Object>, Iterable<Object> {
        /** @description The id of the report to iterate over */
        private Id reportId;

        /**
         * @description The name of the column in the report to return values
         * from and use for indexing
         */
        private String columnName;

        /**
         * @description The integer column offset into the ReportDetailRow that
         * corresponds to the columnName
         */
        private Integer columnOffset;

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
            columnOffset = ReportService.getColumnOffsetByName(
                reportId,
                columnName
            );
        }

        /**
         * @description Implementation of iterator() from Iterable interface
         * @return Iterator<Object>
         */
        public Iterator<Object> iterator() {
            return this;
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
            lastRowValue = row.getDataCells().get(columnOffset).getValue();
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


    /** @description An exception specific to ReportService */
    public virtual class CustomException extends Exception {}

    /**
     * @description An exception for the case that a given column name could
     * not be found in the given report
     */
    public class NoSuchColumnException extends CustomException {}
}