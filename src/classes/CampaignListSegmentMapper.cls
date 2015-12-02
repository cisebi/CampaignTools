public class CampaignListSegmentMapper {
    private static Map<Id, String> sourceNames = new Map<Id, String>();

    public static String getSourceNameById(Id sourceId) {
        if (!sourceNames.containsKey(sourceId)) {
            String name;
            if (Report.sObjectType == sourceId.getSObjectType()) {
                name = 'Report: ' + [SELECT Name FROM Report WHERE Id = :sourceId].Name;
            } else if (Campaign.sObjectType == sourceId.getSObjectType()) {
                name = 'Campaign: ' + [SELECT Name FROM Campaign WHERE Id = :sourceId].Name;
            }
            sourceNames.put(sourceId, name);
        }
        return sourceNames.get(sourceId);
    }

    public static List<CampaignListSegment> getByRootSegmentId(Id rootSegmentId) {
        return create(queryByRootSegmentId(rootSegmentId));
    }

    private static List<Segment__c> queryByRootSegmentId(Id rootSegmentId) {
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

    private static List<CampaignListSegment> create(List<Segment__c> segmentSObjects) {
        List<CampaignListSegment> segments = new List<CampaignListSegment>();
        for (Segment__c segmentSObject : segmentSObjects) {
            segments.add(create(segmentSObject));
        }
        return segments;
    }

    private static CampaignListSegment create(Segment__c segment) {
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

    public abstract class CustomException extends Exception {}
    public class InvalidSegmentSObjectException extends CustomException {}
}