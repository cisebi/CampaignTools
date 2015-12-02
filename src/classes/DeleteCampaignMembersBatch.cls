public class DeleteCampaignMembersBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    private Id campaignId;

    public DeleteCampaignMembersBatch(Id campaignId) {
        this.campaignId = campaignId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM CampaignMember WHERE CampaignId = :campaignId'
        );
    }

    public void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
        delete scope;
        Database.emptyRecycleBin(scope);
    }

    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }
}