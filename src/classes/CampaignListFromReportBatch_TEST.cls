@isTest
public class CampaignListFromReportBatch_TEST {

    private static testMethod void testGetValueIteratorReturnsPresetIterable() {
        List<Object> testIterable = new List<Object>{'Test Iterable Item'};

        CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
            Segment__c.sObjectType.getDescribe().getKeyPrefix() + '00000000000A',
            Report.sObjectType.getDescribe().getKeyPrefix() + '00000000000B',
            'Test_Column_Name',
            'Test Source Name'
        );

        batch.valueIterator = testIterable;

        System.assertEquals(testIterable, batch.getValueIterable());
    }

    private static testMethod void testGetValueIteratorReturnsDefaultIterable() {
        Id testRootSegmentId = Segment__c.sObjectType.getDescribe().getKeyPrefix() + '00000000000A';
        Id testReportId = Report.sObjectType.getDescribe().getKeyPrefix() + '00000000000B';
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
        CampaignListMemberMapperStub listMemberStub = new CampaignListMemberMapperStub();
        listMemberStub.expectedRootSegmentId = Segment__c.sObjectType.getDescribe().getKeyPrefix() + '00000000000A';
        listMemberStub.expectedSourceId = Report.sObjectType.getDescribe().getKeyPrefix() + '00000000000B';
        listMemberStub.expectedSourceName = 'Test';
        listMemberStub.expectedRelatedIds = new List<Id>();
        for (Integer i = 1; i <= 200; i++) {
            String testId = Contact.sObjectType.getDescribe().getKeyPrefix() + padWithZeros(i, 12);
            listMemberStub.expectedRelatedIds.add(Id.valueOf(testId));
        }

        CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
            listMemberStub.expectedRootSegmentId,
            listMemberStub.expectedSourceId,
            'Test_Column_Name',
            listMemberStub.expectedSourceName
        );

        batch.campaignListMemberMapper = listMemberStub;
        batch.valueIterator = (List<Object>) listMemberStub.expectedRelatedIds;
        batch.setScope(200);

        Test.startTest();

        batch.executeBatch();

        Test.stopTest();
    }

    private static String padWithZeros(Integer i, Integer finalLength) {
        String padded = '' + i;
        while(padded.length() < finalLength) {
            padded = '0' + padded;
        }
        return padded;
    }

    private class CampaignListMemberMapperStub implements CampaignListMemberMapper.Interface_x {
        public List<Id> expectedRelatedIds;
        public Id expectedRootSegmentId;
        public Id expectedSourceId;
        public String expectedSourceName;

        public void updateByRelatedIdsAndSource(List<Id> relatedIds, Id rootSegmentId, Id sourceId, String sourceName) {
            System.assertEquals(
                new Set<Id>(expectedRelatedIds),
                new Set<Id>(relatedIds)
            );
            System.assertEquals(expectedRootSegmentId, rootSegmentId);
            System.assertEquals(expectedSourceId, sourceId);
            System.assertEquals(expectedSourceName, sourceName);
        }

        public void addMembersToCampaign(List<CampaignListMember> members, Id campaignId) {}
    }
}