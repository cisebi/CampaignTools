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
private class CampaignListMemberMapper_TEST {
    private static testMethod void testUpdateByRelatedIdsUpdatesMembersAndUpserts() {
        Contact contact1 = new Contact(LastName='Test Contact 1');
        insert contact1;

        Contact contact2 = new Contact(LastName='Test Contact 2');
        insert contact2;

        Lead lead1 = new Lead(
            LastName = 'Test Lead 1',
            Company = 'Test Company'
        );
        insert lead1;

        Lead lead2 = new Lead(
            LastName='Test Lead 2',
            Company = 'Test Company'
        );
        insert lead2;

        Segment__c rootSegment = new Segment__c();
        insert rootSegment;

        Segment__c otherRootSegment = new Segment__c();
        insert otherRootSegment;

        Id sourceId1 = CampaignList_TEST.getNextId(Report.sObjectType);
        String sourceName1 = 'Test Report';

        Id sourceId2 = CampaignList_TEST.getNextId(Campaign.sObjectType);
        String sourceName2 = 'Test Campaign';

        Member__c existingContactMember = new Member__c(
            Contact__c = contact1.Id,
            Root_Segment__c = rootSegment.Id,
            Sources__c = JSON.serialize(new Set<Id>{sourceId2}),
            Source_Names__c = JSON.serialize(new Set<String>{sourceName2})
        );
        insert existingContactMember;

        Member__c existingLeadMember = new Member__c(
            Lead__c = lead1.Id,
            Root_Segment__c = rootSegment.Id
        );
        insert existingLeadMember;

        // these two members belong to a different campaign list, but point to the same contact and leads:

        Member__c existingContactMember2 = new Member__c(
            Contact__c = contact1.Id,
            Root_Segment__c = otherRootSegment.Id,
            Sources__c = JSON.serialize(new Set<Id>{sourceId2}),
            Source_Names__c = JSON.serialize(new Set<String>{sourceName2})
        );
        insert existingContactMember2;

        Member__c existingLeadMember2 = new Member__c(
            Lead__c = lead1.Id,
            Root_Segment__c = otherRootSegment.Id
        );
        insert existingLeadMember2;

        List<Id> relatedIds = new List<Id>{
            contact1.Id,
            contact2.Id,
            lead1.Id,
            lead2.Id
        };

        CampaignListMemberMapper memberMapper = new CampaignListMemberMapper();

        memberMapper.updateByRelatedIdsAndSource(
            relatedIds,
            rootSegment.Id,
            sourceId1,
            sourceName1
        );

        Integer updatedMemberCount = [
            SELECT COUNT()
            FROM Member__c
            WHERE Root_Segment__c = :rootSegment.Id
        ];

        System.assertEquals(4, updatedMemberCount);

        Member__c updatedContactMember = [
            SELECT
                Sources__c,
                Source_Names__c
            FROM Member__c
            WHERE Contact__c = :contact1.Id
            LIMIT 1
        ];

        System.assertEquals(
            new Set<Id>{sourceId1, sourceId2},
            JSON.deserialize(updatedContactMember.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            new Set<String>{sourceName1, sourceName2},
            JSON.deserialize(updatedContactMember.Source_Names__c, Set<String>.class)
        );

        Member__c insertedContactMember = [
            SELECT
                Sources__c,
                Source_Names__c
            FROM Member__c
            WHERE Contact__c = :contact2.Id
            LIMIT 1
        ];

        System.assertEquals(
            new Set<Id>{sourceId1},
            JSON.deserialize(insertedContactMember.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            new Set<String>{sourceName1},
            JSON.deserialize(insertedContactMember.Source_Names__c, Set<String>.class)
        );

        Member__c updatedLeadMember = [
            SELECT
                Sources__c,
                Source_Names__c
            FROM Member__c
            WHERE Lead__c = :lead1.Id
            LIMIT 1
        ];

        System.assertEquals(
            new Set<Id>{sourceId1},
            JSON.deserialize(updatedLeadMember.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            new Set<String>{sourceName1},
            JSON.deserialize(updatedLeadMember.Source_Names__c, Set<String>.class)
        );

        Member__c insertedLeadMember = [
            SELECT
                Sources__c,
                Source_Names__c
            FROM Member__c
            WHERE Lead__c = :lead2.Id
            LIMIT 1
        ];

        System.assertEquals(
            new Set<Id>{sourceId1},
            JSON.deserialize(insertedLeadMember.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            new Set<String>{sourceName1},
            JSON.deserialize(insertedLeadMember.Source_Names__c, Set<String>.class)
        );
    }

    private static testMethod void testAddMembersToCampaign() {
        List<CampaignListMember> listMembers = new List<CampaignListMember>();

        Contact testContact = new Contact(LastName = 'Test Contact');
        insert testContact;

        CampaignListMember member1 = new CampaignListMember(testContact.Id, null);
        listMembers.add(member1);

        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );
        insert testLead;

        CampaignListMember member2 = new CampaignListMember(testLead.Id, null);
        listMembers.add(member2);

        member1.addSource(null, 'Test Source 1');
        member1.addSource(null, 'Test Source 2');
        member2.addSource(null, 'Test Source 2');

        Campaign testCampaign = new Campaign(Name = 'Test Campaign');
        insert testCampaign;

        Test.startTest();

        CampaignListMemberMapper mapper = new CampaignListMemberMapper();

        mapper.addMembersToCampaign(listMembers, testCampaign.Id);

        Test.stopTest();

        List<CampaignMember> createdMembers = [
            SELECT
                ContactId,
                LeadId,
                Source_Names__c
            FROM CampaignMember
            WHERE CampaignId = :testCampaign.Id
        ];

        System.assertEquals(2, createdMembers.size());

        for (CampaignMember cm : createdMembers) {
            Set<String> sourceNames = new Set<String>(cm.Source_Names__c.split(';'));

            if (cm.ContactId == member1.getRelatedId()) {
                System.assertEquals(member1.getRelatedId(), cm.ContactId);
                System.assertEquals(
                    new Set<String>{'Test Source 1', 'Test Source 2'},
                    sourceNames
                );
            } else if (cm.LeadId == member2.getRelatedId()) {
                System.assertEquals(member2.getRelatedId(), cm.LeadId);
                System.assertEquals(
                    new Set<String>{'Test Source 2'},
                    sourceNames
                );
            }
        }
    }
}