@isTest
private class CampaignListSegment_TEST {
    private static testMethod void testAndSegment() {
        Id segmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id parentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);

        CampaignListSegment.AndSegment segment = new CampaignListSegment.AndSegment(
            segmentId,
            rootSegmentId,
            parentId
        );

        System.assertEquals(segmentId, segment.getId());
        System.assertEquals(rootSegmentId, segment.getRootSegmentId());
        System.assertEquals(parentId, segment.getParentId());
    }

    private static testMethod void testOrSegment() {
        Id segmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id parentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);

        CampaignListSegment.OrSegment segment = new CampaignListSegment.OrSegment(
            segmentId,
            rootSegmentId,
            parentId
        );

        System.assertEquals(segmentId, segment.getId());
        System.assertEquals(rootSegmentId, segment.getRootSegmentId());
        System.assertEquals(parentId, segment.getParentId());
    }

    private static testMethod void testCampaignSourceSegment() {
        Id segmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id parentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id sourceId = CampaignList_TEST.getNextId(Campaign.sObjectType);

        CampaignListSegment.CampaignSourceSegment segment = new CampaignListSegment.CampaignSourceSegment(
            segmentId,
            rootSegmentId,
            parentId,
            sourceId,
            false
        );

        System.assertEquals(segmentId, segment.getId());
        System.assertEquals(rootSegmentId, segment.getRootSegmentId());
        System.assertEquals(parentId, segment.getParentId());
        System.assertEquals(sourceId, segment.getSourceId());
        System.assertEquals(false, segment.isExclusion());

        CampaignList_TEST.SegmentMapperStub mapperStub = new CampaignList_TEST.SegmentMapperStub();
        mapperStub.sourceName = 'Test Campaign';
        CampaignList.setSegmentMapper(mapperStub);

        System.assertEquals('Test Campaign', segment.getSourceName());
        System.assertEquals(sourceId, mapperStub.sourceId);

        CampaignListFromCampaignBatch batch = (CampaignListFromCampaignBatch) segment.getBatchProcessor();
        System.assertEquals(rootSegmentId, batch.rootSegmentId);
        System.assertEquals(sourceId, batch.campaignId);
        System.assertEquals('Test Campaign', batch.campaignName);
    }

    private static testMethod void testReportSourceSegment() {
        Id segmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id parentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id sourceId = CampaignList_TEST.getNextId(Report.sObjectType);

        CampaignListSegment.ReportSourceSegment segment = new CampaignListSegment.ReportSourceSegment(
            segmentId,
            rootSegmentId,
            parentId,
            sourceId,
            false,
            'test_column_name'
        );

        System.assertEquals(segmentId, segment.getId());
        System.assertEquals(rootSegmentId, segment.getRootSegmentId());
        System.assertEquals(parentId, segment.getParentId());
        System.assertEquals(sourceId, segment.getSourceId());
        System.assertEquals(false, segment.isExclusion());
        System.assertEquals('test_column_name', segment.getColumnName());

        CampaignList_TEST.SegmentMapperStub mapperStub = new CampaignList_TEST.SegmentMapperStub();
        mapperStub.sourceName = 'Test Report';
        CampaignList.setSegmentMapper(mapperStub);

        System.assertEquals('Test Report', segment.getSourceName());
        System.assertEquals(sourceId, mapperStub.sourceId);

        CampaignListFromReportBatch batch = (CampaignListFromReportBatch) segment.getBatchProcessor();
        System.assertEquals(rootSegmentId, batch.rootSegmentId);
        System.assertEquals(sourceId, batch.reportId);
        System.assertEquals('Test Report', batch.reportName);
        System.assertEquals('test_column_name', batch.idColumnName);
    }
}