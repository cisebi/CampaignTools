@isTest
public class CampaignListService_TEST {
    private static testMethod void testUpdateCampaignFromCampaignList() {
        Id sourceReportId = Schema.SObjectType.Report.getKeyPrefix() + '000000000001';
        Id sourceCampaignId = Schema.SObjectType.Campaign.getKeyPrefix() + '000000000002';
        Id destinationCampaignId = Schema.SObjectType.Campaign.getKeyPrefix() + '000000000003';

        Segment__c rootSegment = new Segment__c(
            Operation__c = 'AND'
        );
        insert rootSegment;

        Segment__c reportSourceSegment = new Segment__c(
            Operation__c = 'SOURCE',
            Parent_Segment__c = rootSegment.Id,
            Root_Segment__c = rootSegment.Id,
            Source_ID__c = sourceReportId,
            Report_Column_Name__c = 'test_column_name',
            Exclude_Source__c = false
        );
        insert reportSourceSegment;

        Segment__c campaignSourceSegment = new Segment__c(
            Operation__c = 'SOURCE',
            Parent_Segment__c = rootSegment.Id,
            Root_Segment__c = rootSegment.Id,
            Source_ID__c = sourceCampaignId,
            Exclude_Source__c = false
        );
        insert campaignSourceSegment;

        BatchableSequenceStub bsStub = new BatchableSequenceStub();


        CampaignListService service = new CampaignListService();

        service.updateCampaignFromCampaignList(destinationCampaignId, rootSegment.Id, bsStub);


        // assert that the batches in this sequence exist in the expected
        // order, with a report source batch and a campaign source batch (in
        // either order)

        List<BatchableSequence.Batch> batches = bsStub.bs.batches;

        System.assert(batches.get(0) instanceof DeleteCampaignMembersBatch);
        System.assert(batches.get(1) instanceof DeleteCampaignListMembersBatch);
        System.assert(batches.get(4) instanceof CampaignListToCampaignBatch);
        System.assert(batches.get(5) instanceof DeleteCampaignListMembersBatch);

        DeleteCampaignMembersBatch deleteCampaignMembersBatch = (DeleteCampaignMembersBatch) batches.get(0);
        DeleteCampaignListMembersBatch deleteCampaignListMembersBatch1 = (DeleteCampaignListMembersBatch) batches.get(1);

        CampaignListFromReportBatch reportBatch;
        CampaignListFromCampaignBatch campaignBatch;

        if (batches.get(2) instanceof CampaignListFromReportBatch) {
            reportBatch = (CampaignListFromReportBatch) batches.get(2);
            campaignBatch = (CampaignListFromCampaignBatch) batches.get(3);
        } else {
            reportBatch = (CampaignListFromReportBatch) batches.get(3);
            campaignBatch = (CampaignListFromCampaignBatch) batches.get(2);
        }

        System.assertNotEquals(null, reportBatch);
        System.assertNotEquals(null, campaignBatch);

        CampaignListToCampaignBatch campaignListToCampaignBatch = (CampaignListToCampaignBatch) batches.get(4);
        DeleteCampaignListMembersBatch deleteCampaignListMembersBatch2 = (DeleteCampaignListMembersBatch) batches.get(5);

        System.assertEquals(destinationCampaignId, deleteCampaignMembersBatch.campaignId);
        System.assertEquals(rootSegment.Id, deleteCampaignListMembersBatch1.rootSegmentId);
        System.assertEquals(rootSegment.Id, reportBatch.rootSegmentId);
        System.assertEquals(sourceReportId, reportBatch.reportId);
        System.assertEquals('test_column_name', reportBatch.idColumnName);
        System.assertEquals(rootSegment.Id, campaignBatch.rootSegmentId);
        System.assertEquals(sourceCampaignId, campaignBatch.campaignId);
        System.assertEquals(rootSegment.Id, campaignListToCampaignBatch.segmentId);
        System.assertEquals(destinationCampaignId, campaignListToCampaignBatch.campaignId);
        System.assertEquals(rootSegment.Id, deleteCampaignListMembersBatch2.rootSegmentId);
    }

    private class BatchableSequenceStub implements BatchableSequence.Interface_x {
        public BatchableSequence bs = new BatchableSequence();
        public BatchableSequence.Batch add(BatchableSequence.Batch b) {
            return bs.add(b);
        }
        public BatchableSequence.Batch add(BatchableSequence.Batch b, Integer scope) {
            return bs.add(b, scope);
        }
        public Id run() {
            return null;
        }
    }
}