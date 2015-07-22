public with sharing class CNode {
	public Node__c node { get; set; }
	public list<CNode> listChildCNodes { get; set; }
    public CNode parentCNode { get; set; }
    public CNode rootCNode { get; set; }
}