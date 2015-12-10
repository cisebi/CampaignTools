/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for clearing a Campaign's associated
 * CampaignMember records
 */
public class DeleteCampaignMembersBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    /** @description the id of the Campaign to clear */
    @TestVisible
    private Id campaignId;

    /**
     * @description Construct the DeleteCampaignMembersBatch class to delete
     * all CampaignMembers from the given Campaign
     *
     * @param campaignId The id of the Campaign to clear
     */
    public DeleteCampaignMembersBatch(Id campaignId) {
        this.campaignId = campaignId;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Database.QueryLocator The CampaignMember records associated with the specified Campaign
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM CampaignMember WHERE CampaignId = :campaignId'
        );
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Deletes the given CampaignMember records and empties them from the
     * recycle bin.
     *
     * @return void
     */
    public void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
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