@isTest
private class CampaignListFromCampaignBatch_TEST {
    private static testMethod void testCampaignListFromCampaignBatch() {
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);

        CampaignList_TEST.TestCampaign testCampaign = new CampaignList_TEST.TestCampaign('Test', 100, 100);

        CampaignListFromCampaignBatch batch = new CampaignListFromCampaignBatch(
            rootSegmentId,
            testCampaign.campaign.Id,
            testCampaign.campaign.Name
        );

        CampaignList_TEST.MemberMapperStub memberMapperStub = new CampaignList_TEST.MemberMapperStub();
        CampaignList.setMemberMapper(memberMapperStub);

        batch.setScope(200);

        Test.startTest();

        batch.executeBatch();

        Test.stopTest();

        Set<Id> relatedIds = new Set<Id>();

        for (Contact c : testCampaign.contacts) {
            relatedIds.add(c.Id);
        }
        for (Lead l : testCampaign.leads) {
            relatedIds.add(l.Id);
        }

        System.assertEquals(
            relatedIds,
            new Set<Id>(memberMapperStub.relatedIds)
        );

        System.assertEquals(rootSegmentId, memberMapperStub.rootSegmentId);
        System.assertEquals(testCampaign.campaign.Id, memberMapperStub.sourceId);
        System.assertEquals(testCampaign.campaign.Name, memberMapperStub.sourceName);
    }
}