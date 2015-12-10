/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A service class that provides methods to perform actions
 * related to campaign lists.
 */
public class CampaignListService {
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
        CampaignListSegmentMapper segmentMapper = new CampaignListSegmentMapper();
        List<CampaignListSegment> segments = segmentMapper.getByRootSegmentId(rootSegmentId);
        CampaignListCriteria criteria = new CampaignListCriteria(segments);

        batchSequence.add(new DeleteCampaignMembersBatch(campaignId), 5000);
        batchSequence.add(new DeleteCampaignListMembersBatch(rootSegmentId), 5000);

        for (CampaignListSegment segment : segments) {
            if (segment instanceof CampaignListSegment.SourceSegment) {
                CampaignListSegment.SourceSegment sourceSegment = (CampaignListSegment.SourceSegment) segment;
                batchSequence.add(sourceSegment.getBatchProcessor());
            }
        }

        batchSequence.add(new CampaignListToCampaignBatch(campaignId, rootSegmentId, criteria), 10000);
        batchSequence.add(new DeleteCampaignListMembersBatch(rootSegmentId), 5000);

        batchSequence.run();
    }
}