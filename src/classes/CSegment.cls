public with sharing class CSegment {
	public Segment__c Segment { get; set; }
	public list<CSegment> listChildCSegments { get; set; }
    public CSegment parentCSegment { get; set; }
    public CSegment rootCSegment { get; set; }

    public CSegment() {
    	Segment = new Segment__c();
    	listChildCSegments = new list<CSegment>();
    	parentCSegment = new CSegment();
    	rootCSegment = new CSegment();
    }
}