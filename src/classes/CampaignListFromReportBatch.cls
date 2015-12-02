public class CampaignListFromReportBatch extends BatchableSequence.Batch implements Database.Batchable<Object> {
    private Id rootSegmentId;
    private Id reportId;
    private String idColumnName;
    private String reportName;

    public CampaignListFromReportBatch(Id rootSegmentId, Id reportId, String idColumnName, String reportName) {
        this.rootSegmentId = rootSegmentId;
        this.reportId = reportId;
        this.idColumnName = idColumnName;
        this.reportName = reportName;
    }

    public ReportService.ReportRowValueIterableIterator start(Database.BatchableContext bc) {
        return new ReportService.ReportRowValueIterableIterator(
            reportId,
            idColumnName
        );
    }

    public void execute(Database.BatchableContext bc, List<Object> scope) {
        List<Id> ids = new List<Id>();
        for (Object o : scope) {
            ids.add((Id) o);
        }

        CampaignListService.updateMembersByRelatedIdsAndSource(
            ids,
            rootSegmentId,
            reportId,
            reportName
        );
    }

    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }
}