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

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(null, rootSegment.Id, null);

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
            Id = Schema.sObjectType.Member__c.getKeyPrefix() + '00000000000A'
        );

        Member__c member2 = new Member__c(
            Id = Schema.sObjectType.Member__c.getKeyPrefix() + '00000000000B'
        );

        Id campaignId = Schema.sObjectType.Campaign.getKeyPrefix() + '000000000001';

        CampaignListCriteriaStub listCriteria = new CampaignListCriteriaStub();
        listCriteria.acceptIds.add(member1.Id);

        CampaignListMemberMapperStub mapperStub = new CampaignListMemberMapperStub();
        mapperStub.expectedCampaignId = campaignId;
        mapperStub.expectedMemberIds.add(member1.Id);

        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(campaignId, null, listCriteria);
        batch.listMemberMapper = mapperStub;

        batch.execute(
            null,
            new List<Member__c>{member1, member2}
        );
    }

    private class CampaignListCriteriaStub implements CampaignListCriteria.Interface_x {
        public Set<Id> acceptIds = new Set<Id>();
        public Boolean meetsCriteria(CampaignListMember m) {
            return acceptIds.contains(m.getId());
        }
    }

    private class CampaignListMemberMapperStub implements CampaignListMemberMapper.Interface_x {
        public Id expectedCampaignId;
        public Set<Id> expectedMemberIds = new Set<Id>();
        public void addMembersToCampaign(List<CampaignListMember> members, Id campaignId) {
            System.assertEquals(expectedCampaignId, campaignId);
            System.assertEquals(expectedMemberIds.size(), members.size());
            for (CampaignListMember member : members) {
                System.assert(expectedMemberIds.contains(member.getId()));
            }
        }
        public void updateByRelatedIdsAndSource(List<Id> a, Id b, Id c, String d) {}
    }

    public static testMethod void testExecuteBatch() {
        CampaignListToCampaignBatch batch = new CampaignListToCampaignBatch(null, null, null);
        batch.setScope(200);

        Test.startTest();

        Id jobId = batch.executeBatch();

        Test.stopTest();

        System.assertEquals(AsyncApexJob.sObjectType, jobId.getSobjectType());
    }
}