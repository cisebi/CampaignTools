public class CampaignListFromCampaignMemberBatch extends BatchableSequence implements Database.Batchable<sObject> {
    private Id campaignId;
    private String campaignName;

    public CampaignListFromCampaignMemberBatch(Id campaignId, String campaignName) {
        this.campaignId = campaignId;
        this.campaignName = campaignName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ContactId, LeadId FROM CampaignMember WHERE Id = :campaignId'
        );
    }

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

        CampaignListService.updateMembersByRelatedIdsAndSource(
            new List<Id>(ids),
            campaignId,
            campaignName
        );
    }

    public override void execute() {
        Database.executeBatch(this, getScope());
    }
}