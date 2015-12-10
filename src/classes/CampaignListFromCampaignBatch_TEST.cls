@isTest
public class CampaignListFromCampaignBatch_TEST {
    private static testMethod void testCampaignListFromCampaignBatch() {
        TestCampaign testCampaign = new TestCampaign('Test', 100, 100);
        Id testRootSegmentId = Segment__c.getSObjectType().getDescribe().getKeyPrefix() + '000000000001';

        CampaignListMemberMapperStub listMemberMapperStub = new CampaignListMemberMapperStub();
        listMemberMapperStub.expectedRootSegmentId = testRootSegmentId;
        listMemberMapperStub.expectedSourceId = testCampaign.campaign.Id;
        listMemberMapperStub.expectedSourceName = testCampaign.campaign.Name;
        listMemberMapperStub.expectedRelatedIds = new List<Id>();
        for (Contact c : testCampaign.contacts) {
            listMemberMapperStub.expectedRelatedIds.add(c.Id);
        }
        for (Lead l : testCampaign.leads) {
            listMemberMapperStub.expectedRelatedIds.add(l.Id);
        }

        CampaignListFromCampaignBatch batch = new CampaignListFromCampaignBatch(
            testRootSegmentId,
            testCampaign.campaign.Id,
            testCampaign.campaign.Name
        );

        batch.campaignListMemberMapper = listMemberMapperStub;
        batch.setScope(200);

        Test.startTest();

        batch.executeBatch();

        Test.stopTest();

        // assertions happen inside stub since it executes in a different transaction
    }

    public class TestCampaign {
        public Campaign campaign;
        public Account company;
        public List<Contact> contacts;
        public List<Lead> leads;
        public List<CampaignMember> campaignMembers;

        public TestCampaign(String name, Integer numberOfContacts, Integer numberOfLeads) {
            campaign = new Campaign(Name = name);
            insert campaign;

            contacts = new List<Contact>();
            leads = new List<Lead>();

            for (Integer i = 0; i < numberOfContacts; i++) {
                contacts.add(new Contact(
                    LastName = 'Test' + i
                ));
            }

            insert contacts;

            company = new Account(Name = 'Test Company');
            insert company;

            for (Integer i = 0; i < numberOfLeads; i++) {
                leads.add(new Lead(
                    LastName = 'Test' + i,
                    Company = company.Id
                ));
            }

            insert leads;

            campaignMembers = new List<CampaignMember>();

            for (Contact c : contacts) {
                campaignMembers.add(new CampaignMember(
                    CampaignId = campaign.Id,
                    ContactId = c.Id
                ));
            }

            for (Lead l : leads) {
                campaignMembers.add(new CampaignMember(
                    CampaignId = campaign.Id,
                    LeadId = l.Id
                ));
            }

            insert campaignMembers;
        }
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