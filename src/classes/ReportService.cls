public class ReportService {
    public static Reports.ReportResults getReportResults(Id reportId, String indexColumn) {
        return getReportResults(reportId, indexColumn, null);
    }

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

    public class ReportRowValueIterableIterator implements Iterator<Object>, Iterable<Object> {
        private Id reportId;
        private String columnName;
        private Integer columnOffset;
        private Object lastRowValue;
        private Boolean hasAllData;
        private Iterator<Reports.ReportDetailRow> currentPageRowIterator;
        private Boolean hasRunReport = false;

        public ReportRowValueIterableIterator(Id reportId, String columnName) {
            this.reportId = reportId;
            this.columnName = columnName;
            columnOffset = ReportService.getColumnOffsetByName(
                reportId,
                columnName
            );
        }

        public Iterator<Object> iterator() {
            return this;
        }

        public Boolean hasNext() {
            if (!hasRunReport) {
                runReport();
            }
            return currentPageRowIterator.hasNext() || !hasAllData;
        }

        public Object next() {
            if (!hasRunReport || !currentPageRowIterator.hasNext()) {
                runReport();
            }
            Reports.ReportDetailRow row = currentPageRowIterator.next();
            lastRowValue = row.getDataCells().get(columnOffset).getValue();
            return lastRowValue;
        }

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

    public virtual class CustomException extends Exception {}
    public class NoSuchColumnException extends CustomException {}
}