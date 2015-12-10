/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for cleaning up a campaign list's temporary
 * Member__c records
 */
public class DeleteCampaignListMembersBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    /** @description The "campaign list" id */
    @TestVisible
    private Id rootSegmentId;

    /**
     * @description Construct the DeleteCampaignListMembersBatch class to clean
     * up the given campaign list's Member__c records
     *
     * @param rootSegmentId The "campaign list" id
     */
    public DeleteCampaignListMembersBatch(Id rootSegmentId) {
        this.rootSegmentId = rootSegmentId;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Database.QueryLocator The Member__c records from the specified campaign list
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM Member__c WHERE Root_Segment__c = :rootSegmentId'
        );
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Deletes the given Member__c records and empties them from the recycle
     * bin.
     *
     * @return void
     */
    public void execute(Database.BatchableContext bc, List<Member__c> scope) {
        delete scope;
        Database.emptyRecycleBin(scope);
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