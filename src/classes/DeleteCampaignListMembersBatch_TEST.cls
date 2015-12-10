@isTest
public class DeleteCampaignListMembersBatch_TEST {
    private static testMethod void testDeleteCampaignListMembersBatch() {
        Segment__c rootSegment = new Segment__c();
        insert rootSegment;

        List<Member__c> members = new List<Member__c>();

        for (Integer i = 0; i < 200; i++) {
            members.add(new Member__c(
                Root_Segment__c = rootSegment.Id
            ));
        }
        insert members;

        Integer listMemberCount = [
            SELECT COUNT()
            FROM Member__c
            WHERE Root_Segment__c = :rootSegment.Id
        ];

        System.assertEquals(200, listMemberCount);

        DeleteCampaignListMembersBatch batch = new DeleteCampaignListMembersBatch(rootSegment.Id);
        batch.setScope(200);

        Test.startTest();

        batch.executeBatch();

        Test.stopTest();

        Integer remainingListMemberCount = [
            SELECT COUNT()
            FROM Member__c
            WHERE Root_Segment__c = :rootSegment.Id
        ];

        System.assertEquals(0, remainingListMemberCount);
    }
}