@isTest
private class SegmentMapper_TEST {
    
    @isTest static void test_method_one() {
        integer numChildren = 3;

        Segment__c rootSegment = new Segment__c(Operation__c=Label.logicAND);
        insert rootSegment;
        
        list<Segment__c> childSegments = new list<Segment__c>();
        for (integer i=0;i<numChildren;i++) {
            childSegments.add(new Segment__c(
                Operation__c = Label.logicOR,
                Root_Segment__c = rootSegment.id,
                Parent_Segment__c = rootSegment.id
            ));
        }
        insert childSegments;

        Segment__c grandchildSegment = new Segment__c(
            Operation__c = Label.logicOR,
            Root_Segment__c = rootSegment.id,
            Parent_Segment__c = childSegments[0].id
        );
        insert grandchildSegment;
        
        CSegment mappedRoot = SegmentMapper.mapRootSegment(rootSegment);

        system.assertEquals(3,mappedRoot.listChildCSegments.size(),'The root segment should have three child segments.');
        Segment__c testGrandchildSegment;
        for (CSegment cs : mappedRoot.listChildCSegments) {
            if (cs.listChildCSegments.size() > 0) {
                testGrandchildSegment = cs.listChildCSegments.get(0).Segment;
            }
        }
        system.assertNotEquals(null,testGrandchildSegment,'The grandchild should exist.');
        system.assertEquals(grandchildSegment.id, testGrandchildSegment.id, 'The correct grandchild should be found.');
    }
}