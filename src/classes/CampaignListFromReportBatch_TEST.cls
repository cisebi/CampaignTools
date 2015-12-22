@isTest
private class CampaignListFromReportBatch_TEST {
    private static testMethod void testGetValueIteratorReturnsPresetIterable() {
        List<Object> testIterable = new List<Object>{'Test Iterable Item'};

        CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
            CampaignList_TEST.getNextId(Segment__c.sObjectType),
            CampaignList_TEST.getNextId(Report.sObjectType),
            'Test_Column_Name',
            'Test Source Name'
        );

        batch.valueIterator = testIterable;

        System.assertEquals(testIterable, batch.getValueIterable());
    }

    private static testMethod void testGetValueIteratorReturnsDefaultIterable() {
        Id testRootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id testReportId = CampaignList_TEST.getNextId(Report.sObjectType);
        CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
            testRootSegmentId,
            testReportId,
            'Test_Column_Name',
            'Test Source Name'
        );

        ReportService.ReportRowValueIterableIterator actualIterator = (ReportService.ReportRowValueIterableIterator) batch.getValueIterable();

        System.assertNotEquals(null, actualIterator);
        System.assertEquals(testReportId, actualIterator.reportId);
        System.assertEquals('Test_Column_Name', actualIterator.columnName);
    }

    private static testMethod void testCampaignListFromReportBatchProcessesIdsFromIterable() {
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id sourceId = CampaignList_TEST.getNextId(Report.sObjectType);
        String sourceName = 'Test';

        CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
            rootSegmentId,
            sourceId,
            'Test_Column_Name',
            sourceName
        );
        
        List<Id> relatedIds = new List<Id>();
        
        for (Integer i = 1; i <= 200; i++) {
            relatedIds.add(CampaignList_TEST.getNextId(Contact.sObjectType));
        }
        
        batch.valueIterator = (List<Object>) relatedIds;
        
        CampaignList_TEST.MemberMapperStub listMemberStub = new CampaignList_TEST.MemberMapperStub();
        CampaignList.setMemberMapper(listMemberStub);                

        batch.setScope(200);

        Test.startTest();

        batch.executeBatch();

        Test.stopTest();
        
        System.assertEquals(relatedIds, listMemberStub.relatedIds);
        System.assertEquals(rootSegmentId, listMemberStub.rootSegmentId);
        System.assertEquals(sourceId, listMemberStub.sourceId);
        System.assertEquals(sourceName, listMemberStub.sourceName);
    }
}