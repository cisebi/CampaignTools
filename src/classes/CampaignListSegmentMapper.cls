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
     * @description Given a list of report or campaign ids, return a map of names for those ids
     *
     * @param sourceIds a list of report or campaign ids
     * @return Map<Id, String>
     */
    @TestVisible
    private Map<Id, String> getSourceNamesByIds(List<Id> sourceIds) {
        Map<Id, String> names = new Map<Id, String>();

        List<Report> reportNames = [
            SELECT Name
            FROM Report
            WHERE Id IN :sourceIds
        ];

        List<Campaign> campaignNames = [
            SELECT Name
            FROM Campaign
            WHERE Id IN :sourceIds
        ];

        for (Report r : reportNames) {
            names.put(r.Id, r.Name);
        }

        for (Campaign c : campaignNames) {
            names.put(c.Id, c.Name);
        }

        return names;
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

        setSourceNamesBySegmentTree(rootSegment);

        return rootSegment;
    }

    /**
     * @description Pluck out the id of the associated source for each source segment in the segment tree
     *
     * @param rootSegment The root segment of the segment tree
     * @return List<Id>
     */
    private List<Id> getSourceIdsFromSegmentTree(CampaignList.Segment rootSegment) {
        Iterator<CampaignList.Segment> it = rootSegment.iterator();

        Set<Id> sourceIds = new Set<Id>();

        while(it.hasNext()) {
            CampaignList.Segment next = it.next();
            if (next instanceof CampaignListSegment.SourceSegment) {
                CampaignListSegment.SourceSegment sourceSegment = (CampaignListSegment.SourceSegment) next;
                sourceIds.add(sourceSegment.getSourceId());
            }
        }

        return new List<Id>(sourceIds);
    }

    /**
     * @description Populate the given segment tree's source nodes with the name of the source they are associated with
     *
     * @param rootSegment The root segment of the segment tree
     * @return void
     */
    private void setSourceNamesBySegmentTree(CampaignList.Segment rootSegment) {
        List<Id> sourceIds = getSourceIdsFromSegmentTree(rootSegment);
        Map<Id, String> sourceNamesById = getSourceNamesByIds(sourceIds);

        Iterator<CampaignList.Segment> it = rootSegment.iterator();

        while (it.hasNext()) {
            CampaignList.Segment next = it.next();
            if (next instanceof CampaignListSegment.SourceSegment) {
                CampaignListSegment.SourceSegment sourceSegment = (CampaignListSegment.SourceSegment) next;
                sourceSegment.setSourceName(sourceNamesById.get(sourceSegment.getSourceId()));
            }
        }
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

    /**
     * Given a segment tree (by root segment), persist that tree to the database by updating existing segments, inserting new ones, and removing segments that are no longer a part of that segment tree.
     *
     * @param rootSegment The root segment of the updated segment tree
     * @return Id (The id of the root segment)
     */
    public Id upsertSegmentTreeByRootSegment(CampaignList.Segment rootSegment) {
        List<CampaignList.Segment> segments = new List<CampaignList.Segment>();
        List<Segment__c> segmentSObjects = new List<Segment__c>();

        Iterator<CampaignList.Segment> segmentIterator = rootSegment.iterator();

        while(segmentIterator.hasNext()) {
            CampaignList.Segment next = segmentIterator.next();
            next.setParentId(null);
            next.setRootSegmentId(null);
            segments.add(next);
            segmentSObjects.add(next.getSObject());
        }

        upsert segmentSObjects;

        for (Integer i = 0; i < segmentSObjects.size(); i++) {
            segments.get(i).setId(segmentSObjects.get(i).Id);
        }

        Id rootSegmentId = segmentSObjects.get(0).Id;

        rootSegment.setRootSegmentId(rootSegmentId);

        segmentSObjects.clear();

        segmentIterator = rootSegment.iterator();

        while(segmentIterator.hasNext()) {
            segmentSObjects.add(segmentIterator.next().getSObject());
        }

        upsert segmentSObjects;

        List<Segment__c> redundantSegments = [
            SELECT Id
            FROM Segment__c
            WHERE Root_Segment__c = :rootSegmentId
            AND Id NOT IN :segmentSObjects
        ];

        delete redundantSegments;

        return rootSegmentId;
    }

    public CampaignList.Segment deserializeSegmentFromJSON(String serialized) {
        SegmentData data = (SegmentData) JSON.deserialize(serialized, SegmentData.class);
        return data.getConcreteInstance();
    }

    private class SegmentData {
        public CampaignList.SegmentType segmentType;
        public Id segmentId;
        public Id rootSegmentId;
        public Id parentId;
        public Id sourceId;
        public Boolean isExclusion;
        public String columnName;
        public String sourceName;
        public List<SegmentData> children;

        public CampaignList.Segment getConcreteInstance() {
            CampaignList.Segment segment;
            if (CampaignList.SegmentType.AND_SEGMENT == segmentType) {
                segment = new CampaignListSegment.AndSegment(segmentId, rootSegmentId, parentId, isExclusion);
            } else if (CampaignList.SegmentType.OR_SEGMENT == segmentType) {
                segment = new CampaignListSegment.OrSegment(segmentId, rootSegmentId, parentId, isExclusion);
            } else if (CampaignList.SegmentType.CAMPAIGN_SOURCE_SEGMENT == segmentType) {
                segment = new CampaignListSegment.CampaignSourceSegment(segmentId, rootSegmentId, parentId, isExclusion, sourceId);
                ((CampaignListSegment.SourceSegment) segment).setSourceName(sourceName);
            } else if (CampaignList.SegmentType.REPORT_SOURCE_SEGMENT == segmentType) {
                segment = new CampaignListSegment.ReportSourceSegment(segmentId, rootSegmentId, parentId, isExclusion, sourceId, columnName);
                ((CampaignListSegment.SourceSegment) segment).setSourceName(sourceName);
            }

            if (null != children) {
                for (SegmentData child : children) {
                    segment.addChild(child.getConcreteInstance());
                }
            }

            return segment;
        }
    }
}