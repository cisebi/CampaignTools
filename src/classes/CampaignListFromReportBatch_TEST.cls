/*
    Copyright (c) 2015 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
@isTest
private class CampaignListFromReportBatch_TEST {
    private static testMethod void testGetValueIteratorReturnsPresetIterable() {
        List<Id> testIterable = new List<Id>{
            CampaignList_TEST.getNextId(Contact.sObjectType)
        };

        CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
            CampaignList_TEST.getNextId(Segment__c.sObjectType),
            CampaignList_TEST.getNextId(Report.sObjectType),
            'Test_Column_Name',
            'Test Source Name'
        );

        batch.idIterator = testIterable;

        System.assertEquals(testIterable, batch.getIdIterable());
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

        ReportService.ReportRowIdIterableIterator actualIterator = (ReportService.ReportRowIdIterableIterator) batch.getIdIterable();

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
        
        batch.idIterator = relatedIds;
        
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