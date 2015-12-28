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
/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A mapper class for CampaignListMember objects
 */
public class CampaignListMemberMapper implements CampaignList.MemberMapper {
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
    public void updateByRelatedIdsAndSource(List<Id> relatedIds, Id rootSegmentId, Id sourceId, String sourceName) {
        Map<Id, CampaignList.Member> members = this.getByRelatedIds(relatedIds, rootSegmentId);

        for (Id id_x : relatedIds) {
            if (!members.containsKey(id_x)) {
                members.put(id_x, new CampaignListMember(id_x, rootSegmentId));
            }
            members.get(id_x).addSource(sourceId, sourceName);
        }

        this.upsertMembers(members.values());
    }

    /**
     * @description Create CampaignMember objects from the given list of CampaignListMembers and add them to the specified Campaign.
     *
     * @param members The list of CampaignListMembers that should be added to the campaign as CampaignMembers
     * @param campaignId The id of the Campaign that the CampaignMembers should be added to
     * @return void
     */
    public void addMembersToCampaign(List<CampaignList.Member> members, Id campaignId) {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for (CampaignList.Member member : members) {
            CampaignMember cm = member.getCampaignMember();
            cm.CampaignId = campaignId;
            campaignMembers.add(cm);
        }

        insert campaignMembers;
    }

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
     * @param rootSegmentId The "campaign list" id being operated on
     * @return Map<Id, CampaignListMember>
     */
    private Map<Id, CampaignList.Member> getByRelatedIds(List<Id> ids, Id rootSegmentId) {
        List<Member__c> members = [
            SELECT
                Contact__c,
                Lead__c,
                Root_Segment__c,
                Source_Names__c,
                Sources__c
            FROM Member__c
            WHERE Root_Segment__c = :rootSegmentId
            AND (
                Contact__c IN :ids
                OR Lead__c IN :ids
            )
        ];

        Map<Id, CampaignList.Member> memberMap = new Map<Id, CampaignList.Member>();

        for (Member__c memberSObject : members) {
            CampaignList.Member m = new CampaignListMember(memberSObject);
            memberMap.put(m.getRelatedId(), m);
        }

        return memberMap;
    }

    /**
     * @description Given a list of CampaignListMember objects, persist these
     * objects to the database as Member__c sObjects.
     *
     * @param members
     * @return void
     */
    private void upsertMembers(List<CampaignList.Member> members) {
        upsert getMemberSObjects(members);
    }

    /**
     * @description Given a list of CampaignListMember objects, deserialize
     * these objects into a list of corresponding Member__c sObjects
     *
     * @param members
     * @return List<Member__c>
     */
    private List<Member__c> getMemberSObjects(List<CampaignList.Member> members) {
        List<Member__c> memberSObjects = new List<Member__c>();

        for (CampaignList.Member member : members) {
            memberSObjects.add(member.getSObject());
        }

        return memberSObjects;
    }
}