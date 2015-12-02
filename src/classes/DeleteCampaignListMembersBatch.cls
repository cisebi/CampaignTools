public class DeleteCampaignListMembersBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    private Id rootSegmentId;

    public DeleteCampaignListMembersBatch(Id rootSegmentId) {
        this.rootSegmentId = rootSegmentId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM Member__c WHERE Root_Segment__c = :rootSegmentId'
        );
    }

    public void execute(Database.BatchableContext bc, List<Member__c> scope) {
        delete scope;
        Database.emptyRecycleBin(scope);
    }

    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }
}