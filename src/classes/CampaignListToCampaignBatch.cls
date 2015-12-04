/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for populating a campaign with CampaignMembers
 * from a campaign list's sources that match the campaign list's inclusion
 * criteria
 */
public class CampaignListToCampaignBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    /** @description The id of the Campaign to populate */
    private Id campaignId;

    /** @description The "campaign list" id */
    private Id segmentId;

    /**
     * @description the CampaignListCriteria corresponding to the given campaign list
     */
    private CampaignListCriteria listCriteria;

    /**
     * @description Construct the batch process to populate the given campaign
     * with CampaignMembers from the given campaign list's sources that match
     * the given CampaignListCriteria
     *
     * @param campaignId The id of the Campaign to populate
     * @param segmentId The "campaign list id
     * @param listCriteria The CampaignListCriteria that corresponds to the given campaign list
     */
    public CampaignListToCampaignBatch(Id campaignId, Id segmentId, CampaignListCriteria listCriteria) {
        this.campaignId = campaignId;
        this.segmentId = segmentId;
        this.listCriteria = listCriteria;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Database.QueryLocator The Member__c records from the specified campaign list
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Contact__c, Lead__c, Root_Segment__c, Sources__c, Source_Names__c FROM Member__c WHERE Root_Segment__c = :segmentId'
        );
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Creates CampaignMembers from the Member__c sObjects that have been
     * prepared for this campaign list.  Each member will be checked to see if
     * it meets the criteria to be included in the campaign, and if so an
     * appropriate CampaignMember record will be created.
     *
     * @return void
     */
    public void execute(Database.BatchableContext bc, List<Member__c> scope) {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for (Member__c m : scope) {
            CampaignListMember member = new CampaignListMember(m);
            if (listCriteria.meetsCriteria(member)) {
                CampaignMember cm = member.getCampaignMember();
                cm.CampaignId = campaignId;
                campaignMembers.add(cm);
            }
        }

        insert campaignMembers;
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