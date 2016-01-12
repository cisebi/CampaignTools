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
 * @description A mapper class for serializing and deserializing
 * CampaignListSegment objects to/from corresponding Segment__c sObjects
 */
public class CampaignListSegmentMapper implements CampaignList.SegmentMapper {
    /**
     * @description A map of source ids to source names used for caching source
     * name lookups
     */
    private static Map<Id, String> sourceNames = new Map<Id, String>();

    /**
     * @description Given the id of a source, i.e. a Report or Campaign, look
     * up the name of that source.  This might execute a SOQL query.
     *
     * @param sourceId The id of the source (i.e. a Report id or a Campaign id
     * @return String (the name of the source)
     */
    public String getSourceNameById(Id sourceId) {
        if (!sourceNames.containsKey(sourceId)) {
            String name;
            try {
                if (Report.sObjectType == sourceId.getSObjectType()) {
                    name = 'Report: ' + [SELECT Name FROM Report WHERE Id = :sourceId].Name;
                } else if (Campaign.sObjectType == sourceId.getSObjectType()) {
                    name = 'Campaign: ' + [SELECT Name FROM Campaign WHERE Id = :sourceId].Name;
                }
            } catch (System.QueryException e) {
                name = '';
            }
            sourceNames.put(sourceId, name);
        }
        return sourceNames.get(sourceId);
    }

    /**
     * @description Given the id of the root segment of a campaign list, get the tree of segments that correspond to that campaign list.
     *
     * @param rootSegmentId The "campaign list" id
     * @return CampaignListSegment
     */
    public CampaignList.Segment getSegmentTreeByRootId(Id rootSegmentId) {
        CampaignList.Segment rootSegment;
        Map<Id, CampaignList.Segment> segments = new Map<Id, CampaignList.Segment>();

        for (Segment__c segment : queryByRootSegmentId(rootSegmentId)) {
            segments.put(segment.Id, create(segment));
        }

        for (CampaignList.Segment segment : segments.values()) {
            Id pid = segment.getParentId();

            if (null == pid) {
                rootSegment = segment;
            } else if (segments.containsKey(pid)) {
                segments.get(pid).addChild(segment);
            } else {
                throw new CampaignList.InvalidSegmentSObjectException(String.format(
                    'Unknown parent ({0}) found in segment {1}',
                    new List<String>{
                        pid,
                        segment.getId()
                    }
                ));
            }
        }

        return rootSegment;
    }

    /**
     * @description Given a "campaign list" id, query for all of the related
     * Segment__c sObjects associated with that campaign list
     *
     * @param rootSegmentId The "campaign list" id
     * @return List<Segment__c>
     */
    private List<Segment__c> queryByRootSegmentId(Id rootSegmentId) {
        return [
            SELECT
                Parent_Segment__c,
                Operation__c,
                Source_ID__c,
                Exclude_Source__c,
                Report_Column_Name__c,
                Root_Segment__c
            FROM Segment__c
            WHERE Root_Segment__c = :rootSegmentId
            OR Id = :rootSegmentId
        ];
    }

    /**
     * @description Given a Segment__c sObject, create a CampaignListSegment
     * data model instance that corresponds to the given Segment__c sObject.
     * The returned CampaignListSegment will be a specific child class of
     * CampaignListSegment appropriate for the given Segment__c sObject.  If
     * the given Segment__c sObject does not correspond to a known
     * CampaignListSegment type, then an InvalidSegmentSObjectException will be
     * thrown.
     *
     * @param segment The Segment__c sObject (including the Parent_Segment__c, Operation__c, Source_ID__c, Exclude_Source__c, Report_Column_Name__c, and Root_Segment__c fields)
     * @return CampaignListSegment
     */
    @TestVisible
    private CampaignListSegment create(Segment__c segment) {
        Id segmentId = segment.Id;
        Id rootSegmentId = segment.Root_Segment__c;
        Id parentId = segment.Parent_Segment__c;
        Boolean isExclusion = segment.Exclude_Source__c;

        if ('OR' == segment.Operation__c) {
            return new CampaignListSegment.OrSegment(segmentId, rootSegmentId, parentId, isExclusion);
        } else if ('AND' == segment.Operation__c) {
            return new CampaignListSegment.AndSegment(segmentId, rootSegmentId, parentId, isExclusion);
        } else if ('SOURCE' == segment.Operation__c) {
            Id sourceId = (Id) segment.Source_ID__c;
            if (Campaign.sObjectType == sourceId.getSObjectType()) {
                return new CampaignListSegment.CampaignSourceSegment(segmentId, rootSegmentId, parentId, isExclusion, sourceId);
            } else if (Report.sObjectType == sourceId.getSObjectType()) {
                String columnName = segment.Report_Column_Name__c;
                return new CampaignListSegment.ReportSourceSegment(segmentId, rootSegmentId, parentId, isExclusion, sourceId, columnName);
            }
        }
        throw new CampaignList.InvalidSegmentSObjectException('Invalid Segment__c object');
    }
}