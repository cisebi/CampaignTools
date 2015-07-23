public with sharing class MembersBuilder {

    public MembersBuilder(ID rootSegmentID) {
        //Retrieve all sources from all children segments of root segment
        List<Source__c> sources = [select ID, Type__c from Segment__c where 
                                    Root_Segment__c = :rootSegmentID and SourceId != null];
        
        List<Member__c> membersToInsert = new List<Member__c>();
        
        for(Source__c source : sources) {
            if(Type__c == 'Campaign') {
                
            } else if(Type__c == 'Report') {
                
            }
        }
        
        //Insert each Member and its sources
    }
}