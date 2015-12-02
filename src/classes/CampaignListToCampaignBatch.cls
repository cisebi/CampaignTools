public class CampaignListToCampaignBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    private Id campaignId;
    private Id segmentId;
    private CampaignListCriteria listCriteria;

    public CampaignListToCampaignBatch(Id campaignId, Id segmentId, CampaignListCriteria listCriteria) {
        this.campaignId = campaignId;
        this.segmentId = segmentId;
        this.listCriteria = listCriteria;
        System.debug(listCriteria);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Contact__c, Lead__c, Root_Segment__c, Sources__c, Source_Names__c FROM Member__c WHERE Root_Segment__c = :segmentId'
        );
    }

    public void execute(Database.BatchableContext bc, List<Member__c> scope) {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for (Member__c m : scope) {
            CampaignListMember member = new CampaignListMember(m);
            System.debug(member);
            System.debug(listCriteria.meetsCriteria(member));
            if (listCriteria.meetsCriteria(member)) {
                CampaignMember cm = member.getCampaignMember();
                cm.CampaignId = campaignId;
                campaignMembers.add(cm);
            }
        }

        insert campaignMembers;
    }

    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }
}