/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A service class that provides methods to perform actions
 * related to campaign lists.
 */
public class CampaignListService {
    /**
     * @description Given a list of related record ids (i.e., Contact or Lead
     * ids), build a collection of CampaignListMember objects that correspond
     * to those related ids. If a related id corresponds to a Member__c
     * sObject, then a CampaignListMember will be constructed from that
     * Member__c object (including deserializing the existing sources that
     * member was already found in).  Otherwise, no CampaignListMember object
     * for that related record will be included in the collection.  The
     * returned collection is keyed by the CampaignListMember's related record
     * id, to allow lookups into this collection by related record id.
     *
     * @param ids A list of Contact or Lead ids
     * @return Map<Id, CampaignListMember>
     */
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

    /**
     * @description Given a list of related record ids, i.e. Contact or Lead
     * record ids, a campaign list id, and the id and name of a source, i.e. a
     * Report or Campaign, create Member__c sObjects that correspond to each
     * related record id.  If the related record already has a corresponding
     * Member__c record, that record will be updated to show that the related
     * record was also found in the given source.  If no existing Member__c
     * sObject exists, then one will be created.
     *
     * @param relatedIds A list of related record ids, i.e. Contact or Lead ids
     * @param rootSegmentId The "campaign list" id being operated on
     * @param sourceId The id of the source Report or Campaign
     * @param sourceName The name of the source Report or Campaign
     * @return void
     */
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

    /**
     * @description Given a list of CampaignListMember objects, persist these
     * objects to the database as Member__c sObjects.
     *
     * @param members
     * @return void
     */
    public static void upsertMembers(List<CampaignListMember> members) {
        upsert getMemberSObjects(members);
    }

    /**
     * @description Given a Campaign id and a corresponding "campaign list" id,
     * clear the Campaign's CampaignMembers and repopulate the Campaign with
     * CampaignMembers sourced from the campaign list's defined sources using
     * the defined campaign list criteria.
     *
     * @param campaignId The id of the Campaign to be updated (note existing CampaignMember records will be deleted and replaced)
     * @param rootSegmentId The "campaign list" id
     * @return void
     */
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

    /**
     * @description Given a list of CampaignListMember objects, deserialize
     * these objects into a list of corresponding Member__c sObjects
     *
     * @param members
     * @return List<Member__c>
     */
    private static List<Member__c> getMemberSObjects(List<CampaignListMember> members) {
        List<Member__c> memberSObjects = new List<Member__c>();

        for (CampaignListMember member : members) {
            memberSObjects.add(member.getSObject());
        }

        return memberSObjects;
    }
}