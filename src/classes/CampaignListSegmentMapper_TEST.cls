@isTest
private class CampaignListSegmentMapper_TEST {
    private static testMethod void testGetSourceNameByCampaignId() {
        Campaign testCampaign = new Campaign(Name='Test Campaign');
        insert testCampaign;

        CampaignListSegmentMapper segmentMapper = new CampaignListSegmentMapper();

        System.assertEquals(
            'Campaign: Test Campaign',
            segmentMapper.getSourceNameById(testCampaign.Id)
        );
    }

    @isTest(SeeAllData=True)
    private static void testGetSourceNameByReportId() {
        Report testReport = [
            SELECT Name
            FROM Report
            WHERE DeveloperName = 'NPSP_Test_Contact_Report'
            LIMIT 1
        ];

        CampaignListSegmentMapper segmentMapper = new CampaignListSegmentMapper();

        System.assertEquals(
            'Report: NPSP Test Contact Report',
            segmentMapper.getSourceNameById(testReport.Id)
        );
    }

    private static testMethod void testGetByRootSegmentId() {
        Segment__c orSegment = new Segment__c(
            Operation__c = 'OR'
        );
        insert orSegment;

        Id rootSegmentId = orSegment.Id;

        Segment__c andSegment = new Segment__c(
            Operation__c = 'AND',
            Parent_Segment__c = orSegment.Id,
            Root_Segment__c = rootSegmentId
        );
        insert andSegment;

        Id campaignSourceId = Campaign.sObjectType.getDescribe().getKeyPrefix() + '000000000001';
        Segment__c campaignSegment = new Segment__c(
            Operation__c = 'SOURCE',
            Source_ID__c = campaignSourceId,
            Exclude_Source__c = true,
            Parent_Segment__c = orSegment.Id,
            Root_Segment__c = rootSegmentId
        );
        insert campaignSegment;

        Id reportSourceId = Report.sObjectType.getDescribe().getKeyPrefix() + '000000000001';
        Segment__c reportSegment = new Segment__c(
            Operation__c = 'SOURCE',
            Source_ID__c = reportSourceId,
            Exclude_Source__c = false,
            Report_Column_Name__c = 'test_column_name',
            Parent_Segment__c = andSegment.Id,
            Root_Segment__c = rootSegmentId
        );
        insert reportSegment;

        CampaignListSegmentMapper segmentMapper = new CampaignListSegmentMapper();
        CampaignListSegment segmentTree = segmentMapper.getSegmentTreeByRootId(
            rootSegmentId
        );

        Map<Id, CampaignListSegment> segmentModelsById = new Map<Id, CampaignListSegment>();

        CampaignListSegment.TreeIterator segmentTreeIterator = segmentTree.iterator();

        while (segmentTreeIterator.hasNext()) {
            CampaignListSegment next = segmentTreeIterator.next();
            segmentModelsById.put(next.getId(), next);
        }

        System.assertEquals(4, segmentModelsById.size());

        CampaignListSegment.OrSegment orSegmentModel = (CampaignListSegment.OrSegment) segmentModelsById.get(orSegment.Id);
        System.assertEquals(null, orSegmentModel.getRootSegmentId());
        System.assertEquals(null, orSegmentModel.getParentId());

        CampaignListSegment.AndSegment andSegmentModel = (CampaignListSegment.AndSegment) segmentModelsById.get(andSegment.Id);
        System.assertEquals(rootSegmentId, andSegmentModel.getRootSegmentId());
        System.assertEquals(orSegment.Id, andSegmentModel.getParentId());

        CampaignListSegment.CampaignSourceSegment campaignSegmentModel = (CampaignListSegment.CampaignSourceSegment) segmentModelsById.get(campaignSegment.Id);

        System.assertEquals(rootSegmentId, campaignSegmentModel.getRootSegmentId());
        System.assertEquals(orSegment.Id, campaignSegmentModel.getParentId());
        System.assertEquals(campaignSourceId, campaignSegmentModel.getSourceId());
        System.assertEquals(true, campaignSegmentModel.isExclusion());

        CampaignListSegment.ReportSourceSegment reportSegmentModel = (CampaignListSegment.ReportSourceSegment) segmentModelsById.get(reportSegment.Id);
        System.assertEquals(rootSegmentId, reportSegmentModel.getRootSegmentId());
        System.assertEquals(andSegment.Id, reportSegmentModel.getParentId());
        System.assertEquals(reportSourceId, reportSegmentModel.getSourceId());
        System.assertEquals(false, reportSegmentModel.isExclusion());
        System.assertEquals('test_column_name', reportSegmentModel.getColumnName());
    }

    private static testMethod void testCreateCampaignListSegmentWithInvalidSegmentOperation() {
        Segment__c invalidSegment = new Segment__c(
            Operation__c = 'INVALID'
        );

        CampaignListSegmentMapper segmentMapper = new CampaignListSegmentMapper();

        Boolean invalidSegmentExceptionThrown = false;

        try {
            segmentMapper.create(invalidSegment);
        } catch (CampaignListSegmentMapper.InvalidSegmentSObjectException e) {
            invalidSegmentExceptionThrown = true;
        }

        System.assert(invalidSegmentExceptionThrown);
    }

    private static testMethod void testCreateCampaignListSegmentWithInvalidSegmentSouceType() {
        Segment__c invalidSegment = new Segment__c(
            Operation__c = 'SOURCE',
            Source_ID__c = Schema.sObjectType.ListView.getKeyPrefix() + '000000000001',
            Exclude_Source__c = false
        );

        CampaignListSegmentMapper segmentMapper = new CampaignListSegmentMapper();

        Boolean invalidSegmentExceptionThrown = false;

        try {
            segmentMapper.create(invalidSegment);
        } catch (CampaignListSegmentMapper.InvalidSegmentSObjectException e) {
            invalidSegmentExceptionThrown = true;
        }

        System.assert(invalidSegmentExceptionThrown);
    }
}