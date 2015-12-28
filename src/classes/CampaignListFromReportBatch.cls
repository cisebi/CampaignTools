/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for gathering potential campaign list members
 * from a given report.
 */
public class CampaignListFromReportBatch extends BatchableSequence.Batch implements Database.Batchable<Id> {
    /**
     * @description The id of the "campaign list" which the members should be
     * added to
     */
    @TestVisible
    private Id rootSegmentId;

    /**
     * @description The id of the Report from which to gather potential
     * members
     */
    @TestVisible
    private Id reportId;

    /**
     * @description The name of the column in the report that holds the id of
     * the Contact or Lead to be included in the campaign list
     */
    @TestVisible
    private String idColumnName;

    /**
     * @description The name of the Report from which to gather potential
     * members
     */
    @TestVisible
    private String reportName;

    /**
     * @description
     */
    @TestVisible
    private Iterable<Id> idIterator;

    /**
     * @description Construct the batch process to gather potential members
     * from a given report for a given campaign list.
     *
     * @param rootSegmentId The id of the "campaign list" which the members should be added to
     * @param reportId The id of the Report from which to gather potential members
     * @param idColumnName The name of the column in the report to retrieve id values from
     * @param reportName The name of the Report from which to gather potential members
     */
    public CampaignListFromReportBatch(Id rootSegmentId, Id reportId, String idColumnName, String reportName) {
        this.rootSegmentId = rootSegmentId;
        this.reportId = reportId;
        this.idColumnName = idColumnName;
        this.reportName = reportName;
    }

    /**
     * @description Get the iterator that will provide ids to the execute()
     * method.  If an iterable is already specified for this batch, it will be
     * used.  Otherwise, an instance of the default implementation,
     * ReportService.ReportRowValueIterableIterator, will be used.
     *
     * @return Iterable<Id>
     */
    @TestVisible
    private Iterable<Id> getIdIterable() {
        if (null == idIterator) {
            idIterator = new ReportService.ReportRowIdIterableIterator(reportId, idColumnName);
        }
        return idIterator;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Iterable<Id> An iterable that will provide values from the id column of the given report
     */
    public Iterable<Id> start(Database.BatchableContext bc) {
        return getIdIterable();
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Creates CampaignListMembers from the report values and persists them
     * to the database.  Each CampaignListMember created will include this
     * report in its list of sources.
     *
     * @return void
     */
    public void execute(Database.BatchableContext bc, List<Id> ids) {
        CampaignList.getMemberMapper().updateByRelatedIdsAndSource(
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