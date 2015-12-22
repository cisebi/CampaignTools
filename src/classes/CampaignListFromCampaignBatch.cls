/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for gathering potential campaign list members
 * from a given campaign.
 */
public class CampaignListFromCampaignBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    /**
     * @description The id of the "campaign list" which the members should be
     * added to
     */
    @TestVisible
    private Id rootSegmentId;

    /**
     * @description The id of the Campaign from which to gather potential
     * members
     */
    @TestVisible
    private Id campaignId;

    /**
     * @description The name of the Campaign from which to gather potential
     * members
     */
    @TestVisible
    private String campaignName;

    /**
     * @description Construct the batch process to gather potential members
     * from a given campaign for a given campaign list.
     *
     * @param rootSegmentId The id of the "campaign list" which the members should be added to
     * @param campaignId The id of the Campaign from which to gather potential members
     * @param campaignName The name of the Campaign from which to gather potential members
     */
    public CampaignListFromCampaignBatch(Id rootSegmentId, Id campaignId, String campaignName) {
        this.rootSegmentId = rootSegmentId;
        this.campaignId = campaignId;
        this.campaignName = campaignName;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Database.QueryLocator The CampaignMembers from the specified source campaign
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ContactId, LeadId FROM CampaignMember WHERE CampaignId = :campaignId'
        );
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Creates CampaignListMembers from the CampaignMembers and persists them
     * to the database.  Each CampaignListMember created will include this
     * campaign in its list of sources.
     *
     * @return void
     */
    public void execute(Database.BatchableContext bc, List<CampaignMember> campaignMembers) {
        Set<Id> ids = new Set<Id>();

        for (CampaignMember cm : campaignMembers) {
            if (null != cm.ContactId) {
                ids.add(cm.ContactId);
            }
            if (null != cm.LeadId) {
                ids.add(cm.LeadId);
            }
        }

        CampaignList.getMemberMapper().updateByRelatedIdsAndSource(
            new List<Id>(ids),
            rootSegmentId,
            campaignId,
            campaignName
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