/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A service class that provides methods to perform actions
 * related to campaign lists.
 */
public class CampaignListService implements CampaignList.Service {
    /**
     * @description Given a Campaign id and a corresponding "campaign list" id,
     * clear the Campaign's CampaignMembers and repopulate the Campaign with
     * CampaignMembers sourced from the campaign list's defined sources using
     * the defined campaign list criteria.
     *
     * @param campaignId The id of the Campaign to be updated (note existing CampaignMember records will be deleted and replaced)
     * @param rootSegmentId The "campaign list" id
     * @return void
     */
    public void updateCampaignFromCampaignList(Id campaignId, Id rootSegmentId) {
        updateCampaignFromCampaignList(campaignId, rootSegmentId, new BatchableSequence());
    }

    /**
     * @description Given a Campaign id and a corresponding "campaign list" id,
     * clear the Campaign's CampaignMembers and repopulate the Campaign with
     * CampaignMembers sourced from the campaign list's defined sources using
     * the defined campaign list criteria.
     *
     * @param campaignId The id of the Campaign to be updated (note existing CampaignMember records will be deleted and replaced)
     * @param rootSegmentId The "campaign list" id
     * @param batchSequence An instance of BatchableSequence to add created batches to
     * @return void
     */
    @TestVisible
    private void updateCampaignFromCampaignList(Id campaignId, Id rootSegmentId, BatchableSequence.Interface_x batchSequence) {
        CampaignList.Segment segmentTree = CampaignList.getSegmentMapper().getSegmentTreeByRootId(rootSegmentId);

        batchSequence.add(new DeleteCampaignMembersBatch(campaignId), 5000);
        batchSequence.add(new DeleteCampaignListMembersBatch(rootSegmentId), 5000);

        Iterator<CampaignList.Segment> segmentTreeIterator = segmentTree.iterator();

        while (segmentTreeIterator.hasNext()) {
            CampaignList.Segment next = segmentTreeIterator.next();
            if (next instanceof CampaignListSegment.SourceSegment) {
                CampaignListSegment.SourceSegment sourceSegment = (CampaignListSegment.SourceSegment) next;
                batchSequence.add(sourceSegment.getBatchProcessor());
            }
        }

        batchSequence.add(new CampaignListToCampaignBatch(campaignId, segmentTree), 10000);
        batchSequence.add(new DeleteCampaignListMembersBatch(rootSegmentId), 5000);

        CampaignList.getService().updateCampaignStatus(campaignId, CampaignList.UpdateStatus.RUNNING);

        batchSequence.run();
    }

    /**
     * @description Update the specified campaign to indicate the status of the
     * campaign being populated from a campaign list @param campaignId The id
     * of the campaign to be updated
     *
     * @param status The status to update the campaign to
     * @return void
     */
    public void updateCampaignStatus(Id campaignId, CampaignList.UpdateStatus status) {
        Campaign c = new Campaign(
            Id = campaignId,
            Campaign_List_Update_Status__c = status.name()
        );

        update c;
    }
}