@isTest
private class CampaignListToCampaignBatch_TEST {
    private static testMethod void testStart() {
        Segment__c rootSegment = new Segment__c();
        insert rootSegment;

        Segment__c someOtherSegment = new Segment__c();
        insert someOtherSegment;

        Member__c member1 = new Member__c(
            Root_Segment__c = rootSegment.Id
        );
        insert member1;

        Member__c member2 = new Member__c(
            Root_Segment__c = someOtherSegment.Id
        );
        insert member2;

        CampaignList_TEST.SegmentStub rootSegmentStub = new CampaignList_TEST.SegmentStub();
        rootSegmentStub.segmentId = rootSegment.Id;

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(null, rootSegmentStub);

        Database.QueryLocatorIterator qli = batch.start(null).iterator();

        List<Member__c> queriedMembers = new List<Member__c>();
        while (qli.hasNext()) {
            queriedMembers.add((Member__c) qli.next());
        }

        System.assertEquals(1, queriedMembers.size());
        System.assertEquals(member1.Id, queriedMembers.get(0).Id);
    }

    private static testMethod void testCampaignListToCampaignBatchExecute() {
        Member__c member1 = new Member__c(
            Id = CampaignList_TEST.getNextId(Member__c.sObjectType)
        );

        Member__c member2 = new Member__c(
            Id = CampaignList_TEST.getNextId(Member__c.sObjectType)
        );

        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);

        CampaignList_TEST.SegmentStub rootSegment = new CampaignList_TEST.SegmentStub();
        rootSegment.acceptIds.add(member1.Id);

        CampaignList_TEST.MemberMapperStub mapperStub = new CampaignList_TEST.MemberMapperStub();
        CampaignList.setMemberMapper(mapperStub);

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(campaignId, rootSegment);

        batch.execute(
            null,
            new List<Member__c>{member1, member2}
        );

        System.assertEquals(campaignId, mapperStub.campaignId);
        System.assertEquals(1, mapperStub.members.size());
        System.assertEquals(member1.Id, mapperStub.members.get(0).getId());
    }

    public static testMethod void testExecuteBatch() {
        CampaignList_TEST.SegmentStub rootSegment = new CampaignList_TEST.SegmentStub();
        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(null, rootSegment);
        batch.setScope(200);

        CampaignList.setService(new CampaignList_TEST.ServiceStub());

        Test.startTest();

        Id jobId = batch.executeBatch();

        Test.stopTest();

        System.assertEquals(AsyncApexJob.sObjectType, jobId.getSobjectType());
    }

    public static testMethod void testFinish() {
        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(campaignId, null);

        CampaignList_TEST.ServiceStub listServiceStub = new CampaignList_TEST.ServiceStub();

        CampaignList.setService(listServiceStub);

        batch.finish(null);

        System.assertEquals(campaignId, listServiceStub.updatedCampaignId);
        System.assertEquals(CampaignList.UpdateStatus.SUCCESS, listServiceStub.updatedStatus);
    }
}