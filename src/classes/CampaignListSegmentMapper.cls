/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A mapper class for serializing and deserializing
 * CampaignListSegment objects to/from corresponding Segment__c sObjects
 */
public class CampaignListSegmentMapper implements MapperInterface {
    public interface MapperInterface {
        String getSourceNameById(Id sourceId);
        CampaignListSegment getSegmentTreeByRootId(Id rootSegmentId);
    }

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
    public CampaignListSegment getSegmentTreeByRootId(Id rootSegmentId) {
        CampaignListSegment rootSegment;
        Map<Id, CampaignListSegment> segments = new Map<Id, CampaignListSegment>();

        for (Segment__c segment : queryByRootSegmentId(rootSegmentId)) {
            segments.put(segment.Id, create(segment));
        }

        for (CampaignListSegment segment : segments.values()) {
            Id pid = segment.getParentId();

            if (null == pid) {
                rootSegment = segment;
            } else if (segments.containsKey(pid)) {
                segments.get(pid).addChild(segment);
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

        if ('OR' == segment.Operation__c) {
            return new CampaignListSegment.OrSegment(segmentId, rootSegmentId, parentId);
        } else if ('AND' == segment.Operation__c) {
            return new CampaignListSegment.AndSegment(segmentId, rootSegmentId, parentId);
        } else if ('SOURCE' == segment.Operation__c) {
            Id sourceId = (Id) segment.Source_ID__c;
            Boolean isExcluded = segment.Exclude_Source__c;

            if (Campaign.sObjectType == sourceId.getSObjectType()) {
                return new CampaignListSegment.CampaignSourceSegment(segmentId, rootSegmentId, parentId, sourceId, isExcluded);
            } else if (Report.sObjectType == sourceId.getSObjectType()) {
                String columnName = segment.Report_Column_Name__c;
                return new CampaignListSegment.ReportSourceSegment(segmentId, rootSegmentId, parentId, sourceId, isExcluded, columnName);
            }
        }
        throw new InvalidSegmentSObjectException('Invalid Segment__c object');
    }

    /** @description An exception specific to CampaignListSegmentMapper */
    public abstract class CustomException extends Exception {}

    /**
     * @description An exception for the case where a Segment__c record does
     * not correspond to a known segment type
     */
    public class InvalidSegmentSObjectException extends CustomException {}
}