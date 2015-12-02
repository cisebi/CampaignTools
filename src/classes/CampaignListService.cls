public class CampaignListService {
    public static Map<Id, CampaignListMember> getByRelatedIds(List<Id> ids) {
        List<Member__c> members = [
            SELECT
                Contact__c,
                Lead__c,
                Root_Segment__c,
                Source_Names__c,
                Sources__c
            FROM Member__c
            WHERE Contact__c IN :ids
            OR Lead__c IN :ids
        ];

        Map<Id, CampaignListMember> memberMap = new Map<Id, CampaignListMember>();

        for (Member__c memberSObject : members) {
            CampaignListMember m = new CampaignListMember(memberSObject);
            memberMap.put(m.getRelatedId(), m);
        }

        return memberMap;
    }

    public static void updateMembersByRelatedIdsAndSource(List<Id> relatedIds, Id rootSegmentId, Id sourceId, String sourceName) {
        Map<Id, CampaignListMember> members = getByRelatedIds(relatedIds);

        for (Id id_x : relatedIds) {
            if (!members.containsKey(id_x)) {
                members.put(id_x, new CampaignListMember(id_x, rootSegmentId));
            }
            members.get(id_x).addSource(sourceId, sourceName);
        }

        upsertMembers(members.values());
    }

    public static void upsertMembers(List<CampaignListMember> members) {
        upsert getMemberSObjects(members);
    }

    public static void updateCampaignFromCampaignList(Id campaignId, Id rootSegmentId) {
        List<CampaignListSegment> segments = CampaignListSegmentMapper.getByRootSegmentId(rootSegmentId);
        CampaignListCriteria criteria = new CampaignListCriteria(segments);

        BatchableSequence batchSequence = new BatchableSequence();
        batchSequence.add(new DeleteCampaignMembersBatch(campaignId), 5000);
        batchSequence.add(new DeleteCampaignListMembersBatch(rootSegmentId), 5000);

        for (CampaignListSegment segment : segments) {
            if (segment instanceof CampaignListSegment.SourceSegment) {
                CampaignListSegment.SourceSegment sourceSegment = (CampaignListSegment.SourceSegment) segment;
                batchSequence.add(sourceSegment.getBatchProcessor());
            }
        }

        batchSequence.add(new CampaignListToCampaignBatch(campaignId, rootSegmentId, criteria), 10000);
        batchSequence.add(new DeleteCampaignListMembersBatch(rootSegmentId), 5000);

        batchSequence.run();
    }

    private static List<Member__c> getMemberSObjects(List<CampaignListMember> members) {
        List<Member__c> memberSObjects = new List<Member__c>();

        for (CampaignListMember member : members) {
            memberSObjects.add(member.getSObject());
        }

        return memberSObjects;
    }
}