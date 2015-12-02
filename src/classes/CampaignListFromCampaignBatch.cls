public class CampaignListFromCampaignBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    private Id rootSegmentId;
    private Id campaignId;
    private String campaignName;

    public CampaignListFromCampaignBatch(Id rootSegmentId, Id campaignId, String campaignName) {
        this.rootSegmentId = rootSegmentId;
        this.campaignId = campaignId;
        this.campaignName = campaignName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ContactId, LeadId FROM CampaignMember WHERE CampaignId = :campaignId'
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
            rootSegmentId,
            campaignId,
            campaignName
        );
    }

    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }
}