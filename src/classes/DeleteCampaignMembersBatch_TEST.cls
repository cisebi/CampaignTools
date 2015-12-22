@isTest
private class DeleteCampaignMembersBatch_TEST {
    private static testMethod void testDeleteCampaignMembersBatch() {
        CampaignList_TEST.TestCampaign tc = new CampaignList_TEST.TestCampaign('Test', 100, 100);

        Integer memberCount = [
            SELECT COUNT()
            FROM CampaignMember
            WHERE CampaignId = :tc.campaign.Id
        ];

        System.assertEquals(200, memberCount);

        DeleteCampaignMembersBatch batch = new DeleteCampaignMembersBatch(tc.campaign.Id);
        batch.setScope(200);

        Test.startTest();

        batch.executeBatch();

        Test.stopTest();

        Integer remainingMemberCount = [
            SELECT COUNT()
            FROM CampaignMember
            WHERE CampaignId = :tc.campaign.Id
        ];

        System.assertEquals(0, remainingMemberCount);
    }
}