/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for gathering potential campaign list members
 * from a given report.
 */
public class CampaignListFromReportBatch extends BatchableSequence.Batch implements Database.Batchable<Object> {
    /**
     * @description The id of the "campaign list" which the members should be
     * added to
     */
    private Id rootSegmentId;

    /**
     * @description The id of the Report from which to gather potential
     * members
     */
    private Id reportId;

    /**
     * @description The name of the column in the report that holds the id of
     * the Contact or Lead to be included in the campaign list
     */
    private String idColumnName;

    /**
     * @description The name of the Report from which to gather potential
     * members
     */
    private String reportName;

    /**
     * @description Construct the batch process to gather potential members
     * from a given report for a given campaign list.
     *
     * @param rootSegmentId The id of the "campaign list" which the members should be added to
     * @param reportId The id of the Report from which to gather potential members
     * @param reportName The name of the Report from which to gather potential members
     */
    public CampaignListFromReportBatch(Id rootSegmentId, Id reportId, String idColumnName, String reportName) {
        this.rootSegmentId = rootSegmentId;
        this.reportId = reportId;
        this.idColumnName = idColumnName;
        this.reportName = reportName;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return ReportService.ReportRowValueIterableIterator An iterable that will provide values from the id column of the given report
     */
    public ReportService.ReportRowValueIterableIterator start(Database.BatchableContext bc) {
        return new ReportService.ReportRowValueIterableIterator(
            reportId,
            idColumnName
        );
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Creates CampaignListMembers from the report values and persists them
     * to the database.  Each CampaignListMember created will include this
     * report in its list of sources.
     *
     * @return void
     */
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

    /**
     * @description This will cause this batch to be executed, i.e.,
     * Database.executeBatch() will be called with this batch as the batch to
     * execute and this batch's scope.
     *
     * @return Id The id of the AsyncApexJob returned by Database.executeBatch()
     */
    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }
}