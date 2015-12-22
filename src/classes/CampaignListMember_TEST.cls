@isTest
private class CampaignListMember_TEST {
    private static testMethod void testContactMemberFromSObject() {
        Id memberId = CampaignList_TEST.getNextId(Member__c.sObjectType);
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id contactId = CampaignList_TEST.getNextId(Contact.sObjectType);

        Id reportId = CampaignList_TEST.getNextId(Report.sObjectType);
        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);
        Id campaignId2 = CampaignList_TEST.getNextId(Campaign.sObjectType);

        Set<Id> sourceIds = new Set<Id>{reportId, campaignId};
        Set<String> sourceNames = new Set<String>{'Report Name', 'Campaign Name'};

        Member__c m = new Member__c(
            Id = memberId,
            Root_Segment__c = rootSegmentId,
            Contact__c = contactId,
            Sources__c = JSON.serialize(sourceIds),
            Source_Names__c = JSON.serialize(sourceNames)
        );

        CampaignListMember member = new CampaignListMember(m);

        System.assertEquals(memberId, member.getId());
        System.assertEquals(contactId, member.getRelatedId());
        System.assert(member.isFromSource(reportId));
        System.assert(member.isFromSource(campaignId));
        System.assert(!member.isFromSource(campaignId2));

        Member__c memberSObject = member.getSObject();

        System.assertEquals(memberId, memberSObject.Id);
        System.assertEquals(rootSegmentId, memberSObject.Root_Segment__c);
        System.assertEquals(contactId, memberSObject.Contact__c);
        System.assertEquals(null, memberSObject.Lead__c);
        System.assertEquals(
            sourceIds,
            (Set<Id>) JSON.deserialize(memberSObject.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            sourceNames,
            (Set<String>) JSON.deserialize(memberSObject.Source_Names__c, Set<String>.class)
        );

        CampaignMember cm = member.getCampaignMember();

        System.assertEquals(contactId, cm.ContactId);
        System.assertEquals(null, cm.LeadId);
        System.assertEquals(
            sourceNames,
            new Set<String>(cm.Source_Names__c.split(';'))
        );
    }

    private static testMethod void testLeadMemberFromSObject() {
        Id memberId = CampaignList_TEST.getNextId(Member__c.sObjectType);
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id leadId = CampaignList_TEST.getNextId(Lead.sObjectType);

        Id reportId = CampaignList_TEST.getNextId(Report.sObjectType);
        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);
        Id campaignId2 = CampaignList_TEST.getNextId(Campaign.sObjectType);

        Set<Id> sourceIds = new Set<Id>{reportId, campaignId};
        Set<String> sourceNames = new Set<String>{'Report Name', 'Campaign Name'};

        Member__c m = new Member__c(
            Id = memberId,
            Root_Segment__c = rootSegmentId,
            Lead__c = leadId,
            Sources__c = JSON.serialize(sourceIds),
            Source_Names__c = JSON.serialize(sourceNames)
        );

        CampaignListMember member = new CampaignListMember(m);

        System.assertEquals(memberId, member.getId());
        System.assertEquals(leadId, member.getRelatedId());
        System.assert(member.isFromSource(reportId));
        System.assert(member.isFromSource(campaignId));
        System.assert(!member.isFromSource(campaignId2));

        Member__c memberSObject = member.getSObject();

        System.assertEquals(memberId, memberSObject.Id);
        System.assertEquals(rootSegmentId, memberSObject.Root_Segment__c);
        System.assertEquals(leadId, memberSObject.Lead__c);
        System.assertEquals(null, memberSObject.Contact__c);
        System.assertEquals(
            sourceIds,
            (Set<Id>) JSON.deserialize(memberSObject.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            sourceNames,
            (Set<String>) JSON.deserialize(memberSObject.Source_Names__c, Set<String>.class)
        );

        CampaignMember cm = member.getCampaignMember();

        System.assertEquals(leadId, cm.LeadId);
        System.assertEquals(null, cm.ContactId);
        System.assertEquals(
            sourceNames,
            new Set<String>(cm.Source_Names__c.split(';'))
        );
    }

    private static testMethod void testContactMemberFromIds() {
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id contactId = CampaignList_TEST.getNextId(Contact.sObjectType);

        Id reportId = CampaignList_TEST.getNextId(Report.sObjectType);
        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);

        Set<Id> sourceIds = new Set<Id>{reportId, campaignId};
        Set<String> sourceNames = new Set<String>{'Report Name', 'Campaign Name'};

        CampaignListMember member = new CampaignListMember(contactId, rootSegmentId);

        System.assertEquals(contactId, member.getRelatedId());

        member.addSource(reportId, 'Report Name');
        member.addSource(campaignId, 'Campaign Name');

        System.assert(member.isFromSource(reportId));
        System.assert(member.isFromSource(campaignId));
        System.assert(!member.isFromSource(rootSegmentId));

        Member__c memberSObject = member.getSObject();

        System.assertEquals(null, memberSObject.Id);
        System.assertEquals(rootSegmentId, memberSObject.Root_Segment__c);
        System.assertEquals(contactId, memberSObject.Contact__c);
        System.assertEquals(null, memberSObject.Lead__c);
        System.assertEquals(
            sourceIds,
            (Set<Id>) JSON.deserialize(memberSObject.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            sourceNames,
            (Set<String>) JSON.deserialize(memberSObject.Source_Names__c, Set<String>.class)
        );
    }

    private static testMethod void testLeadMemberFromIds() {
        Id rootSegmentId = CampaignList_TEST.getNextId(Segment__c.sObjectType);
        Id leadId = CampaignList_TEST.getNextId(Lead.sObjectType);

        Id reportId = CampaignList_TEST.getNextId(Report.sObjectType);
        Id campaignId = CampaignList_TEST.getNextId(Campaign.sObjectType);

        Set<Id> sourceIds = new Set<Id>{reportId, campaignId};
        Set<String> sourceNames = new Set<String>{'Report Name', 'Campaign Name'};

        CampaignListMember member = new CampaignListMember(leadId, rootSegmentId);

        System.assertEquals(leadId, member.getRelatedId());

        member.addSource(reportId, 'Report Name');
        member.addSource(campaignId, 'Campaign Name');

        System.assert(member.isFromSource(reportId));
        System.assert(member.isFromSource(campaignId));
        System.assert(!member.isFromSource(rootSegmentId));

        Member__c memberSObject = member.getSObject();

        System.assertEquals(null, memberSObject.Id);
        System.assertEquals(rootSegmentId, memberSObject.Root_Segment__c);
        System.assertEquals(leadId, memberSObject.Lead__c);
        System.assertEquals(null, memberSObject.Contact__c);
        System.assertEquals(
            sourceIds,
            (Set<Id>) JSON.deserialize(memberSObject.Sources__c, Set<Id>.class)
        );
        System.assertEquals(
            sourceNames,
            (Set<String>) JSON.deserialize(memberSObject.Source_Names__c, Set<String>.class)
        );
    }
}