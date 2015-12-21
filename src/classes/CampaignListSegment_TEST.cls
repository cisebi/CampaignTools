@isTest
private class CampaignListSegment_TEST {
    private static testMethod void testAndSegment() {
        Id segmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000A';
        Id rootSegmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000B';
        Id parentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000C';

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
        Id segmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000A';
        Id rootSegmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000B';
        Id parentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000C';

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
        Id segmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000A';
        Id rootSegmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000B';
        Id parentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000C';
        Id sourceId = Schema.sObjectType.Campaign.getKeyPrefix() + '00000000000D';

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

        CampaignListSegmentMapperStub mapperStub = new CampaignListSegmentMapperStub();
        mapperStub.expectedSourceId = sourceId;
        mapperStub.sourceName = 'Test Campaign';

        segment.segmentMapper = mapperStub;

        System.assertEquals('Test Campaign', segment.getSourceName());

        CampaignListFromCampaignBatch batch = (CampaignListFromCampaignBatch) segment.getBatchProcessor();
        System.assertEquals(rootSegmentId, batch.rootSegmentId);
        System.assertEquals(sourceId, batch.campaignId);
        System.assertEquals('Test Campaign', batch.campaignName);
    }

    private static testMethod void testReportSourceSegment() {
        Id segmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000A';
        Id rootSegmentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000B';
        Id parentId = Schema.sObjectType.Segment__c.getKeyPrefix() + '00000000000C';
        Id sourceId = Schema.sObjectType.Report.getKeyPrefix() + '00000000000D';

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

        CampaignListSegmentMapperStub mapperStub = new CampaignListSegmentMapperStub();
        mapperStub.expectedSourceId = sourceId;
        mapperStub.sourceName = 'Test Report';

        segment.segmentMapper = mapperStub;

        System.assertEquals('Test Report', segment.getSourceName());

        CampaignListFromReportBatch batch = (CampaignListFromReportBatch) segment.getBatchProcessor();
        System.assertEquals(rootSegmentId, batch.rootSegmentId);
        System.assertEquals(sourceId, batch.reportId);
        System.assertEquals('Test Report', batch.reportName);
        System.assertEquals('test_column_name', batch.idColumnName);
    }

    private class CampaignListSegmentMapperStub implements CampaignListSegmentMapper.MapperInterface {
        public Id expectedSourceId;
        public String sourceName;
        public String getSourceNameById(Id sourceId) {
            System.assertEquals(expectedSourceId, sourceId);
            return sourceName;
        }
        public CampaignListSegment getSegmentTreeByRootId(Id rootSegmentId) {
            return null;
        }
    }
}