/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for populating a campaign with CampaignMembers
 * from a campaign list's sources that match the campaign list's inclusion
 * criteria
 */
public class CampaignListToCampaignBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    /** @description The id of the Campaign to populate */
    @TestVisible
    private Id campaignId;

    /** @description The "campaign list" root segment */
    @TestVisible
    private CampaignListSegment.Interface_x rootSegment;

    /**
     * @description the ListMemberMapper to use for manipulating
     * CampaignListMembers
     */
    @TestVisible
    private CampaignListMemberMapper.Interface_x listMemberMapper = new CampaignListMemberMapper();

    /**
     * @description the CampaignListService to use for updating Campaign status
     */
    @TestVisible
    private CampaignListService.Interface_x listService = new CampaignListService();

    /**
     * @description Construct the batch process to populate the given campaign
     * with CampaignMembers from the given campaign list's sources that match
     * the given CampaignListCriteria
     *
     * @param campaignId The id of the Campaign to populate
     * @param rootSegment The "campaign list" root segment
     */
    public CampaignListToCampaignBatch(Id campaignId, CampaignListSegment.Interface_x rootSegment) {
        this.campaignId = campaignId;
        this.rootSegment = rootSegment;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Database.QueryLocator The Member__c records from the specified campaign list
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id rootSegmentId = rootSegment.getId();
        return Database.getQueryLocator(
            'SELECT Contact__c, Lead__c, Root_Segment__c, Sources__c, Source_Names__c FROM Member__c WHERE Root_Segment__c = :rootSegmentId'
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
        List<CampaignListMember> eligibleMembers = new List<CampaignListMember>();

        for (Member__c m : scope) {
            CampaignListMember member = new CampaignListMember(m);
            if (member.meetsCriteria(rootSegment)) {
                eligibleMembers.add(member);
            }
        }

        listMemberMapper.addMembersToCampaign(eligibleMembers, campaignId);
    }

    /**
     * @description Implementation of finish() from Database.Batchable
     * interface.  This will call BatachableSequence's finish() method and then
     * update the specified campaign's status to indicate that it was
     * successfully populated from the specified campaign list.
    *
    * @param bc The BatchableContext for this batch
    * @return void
    */
    public override void finish(Database.BatchableContext bc) {
        super.finish(bc);
        listService.updateCampaignStatus(
            campaignId,
            CampaignListService.UpdateStatus.SUCCESS
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