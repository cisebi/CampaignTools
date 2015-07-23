public with sharing class SegmentMapper {

    public static CSegment mapRootSegment(Segment__c rootSegment) {

        map<id, Segment__c> segMap = new map<id, Segment__c>(
            [SELECT Id, Operation__c, Parent_Segment__c, Root_Segment__c, Source_Type__c, Source_Id__c, Exclude_Source__c,
            (SELECT Id FROM Segments__r) 
            FROM Segment__c WHERE Root_Segment__c = :rootSegment.Id OR Id = :rootSegment.Id]
        );
        
        map<id, CSegment> mapCSegment = new map<id, CSegment>();

        //fill out CSegment map
        for (Segment__c seg : segMap.values()) {
            CSegment CSeg = new CSegment();
            CSeg.Segment = segMap.get(seg.id);
            mapCSegment.put(seg.Id, CSeg);
        }
        
        //fill out parent, root, and child lists with CSegments
        for (CSegment CSeg : mapCSegment.values()) {

            if (CSeg.Segment.Parent_Segment__c!=null)
                CSeg.parentCSegment = mapCSegment.get(CSeg.Segment.Parent_Segment__c);

            if (CSeg.Segment.Root_Segment__c!=null)
                CSeg.rootCSegment = mapCSegment.get(CSeg.Segment.Root_Segment__c);

            if (CSeg.Segment.getSObjects('Segments__r')!=null) {
                for (Segment__c childseg : CSeg.Segment.getSObjects('Segments__r')) {
                    CSeg.listChildCSegments.add(mapCSegment.get(childseg.id));
                }
            }
        }
        
        return mapCSegment.get(rootSegment.Id);
    }
}