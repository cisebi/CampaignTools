public class CampaignListMember {
    private Id memberId;
    private Id rootSegmentId;
    private Id relatedId;
    private Set<Id> sourceIds = new Set<Id>();
    private Set<String> sourceNames = new Set<String>();

    public CampaignListMember(Member__c memberSObject) {
        if (null != memberSObject.Id) {
            memberId = memberSObject.Id;
        }

        if (null != memberSObject.Root_Segment__c) {
            rootSegmentId = memberSObject.Root_Segment__c;
        }

        if (null == memberSObject.Contact__c) {
            relatedId = memberSObject.Lead__c;
        } else {
            relatedId = memberSObject.Contact__c;
        }

        if (!String.isBlank(memberSObject.Sources__c)) {
            sourceIds = (Set<Id>) JSON.deserializeStrict(
                memberSObject.Sources__c,
                Set<Id>.class
            );
        }

        if (!String.isBlank(memberSObject.Source_Names__c)) {
            sourceNames = (Set<String>) JSON.deserializeStrict(
                memberSObject.Source_Names__c,
                Set<String>.class
            );
        }
    }

    public CampaignListMember(Id relatedId, Id rootSegmentId) {
        this.relatedId = relatedId;
        this.rootSegmentId = rootSegmentId;
    }

    public Id getRelatedId() {
        return relatedId;
    }

    public void addSource(Id sourceId, String sourceName) {
        sourceIds.add(sourceId);
        sourceNames.add(sourceName);
    }

    public Boolean isFromSource(Id sourceId) {
        return sourceIds.contains(sourceId);
    }

    public Member__c getSObject() {
        Member__c member = new Member__c(
            Id = memberId,
            Root_Segment__c = rootSegmentId,
            Sources__c = JSON.serialize(sourceIds),
            Source_Names__c = JSON.serialize(sourceNames)
        );

        if (null != relatedId) {
            if (Contact.sObjectType == relatedId.getSObjectType()) {
                member.Contact__c = relatedId;
            }
            if (Lead.sObjectType == relatedId.getSObjectType()) {
                member.Lead__c = relatedId;
            }
        }

        return member;
    }

    public CampaignMember getCampaignMember() {
        CampaignMember cm = new CampaignMember();

        if (null != relatedId) {
            if (Contact.sObjectType == relatedId.getSObjectType()) {
                cm.ContactId = relatedId;
            }
            if (Lead.sObjectType == relatedId.getSObjectType()) {
                cm.LeadId = relatedId;
            }
        }

        if (!sourceNames.isEmpty()) {
            cm.Source_Names__c = String.join(
                new List<String>(sourceNames),
                ';'
            );
        }

        return cm;
    }
}