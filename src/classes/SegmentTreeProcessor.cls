/*
    Copyright (c) 2015 Salesforce.com Foundation
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
* @author Salesforce.com Foundation
* @date 2015
*
* @group Segments
*
* @description contains the logic to take an in-memory segment tree, and
* compute which saved member records should copied to the campaign list.
*
*/

public with sharing class SegmentTreeProcessor {
    
    /*******************************************************************************************************
    * @description process the segment tree and mark which saved member records should be in the result set.
    * @param seg a segment within the segment tree
    * @param member the member record to process
    * @return void
    ********************************************************************************************************/
    public static void processSegmentTree(Segment__c segRoot, list<Member__c> listMember) {
        for (Member__c member : listMember) {
            member.Include_in_List__c = includeMemberInSegmentTree(member, segRoot);
        }
    }

    /*******************************************************************************************************
    * @description should this member be included given this segment subtree?
    * this method uses recursion to process the subtree it is provided.
    * @param member the member record to analyze
    * @param segment a segment within the segment tree
    * @return true if the member should be included, false if not.
    ********************************************************************************************************/
    public static boolean includeMemberInSegmentTree(Member__c member, Segment__c segment) {
    
        // handle a leaf segment, which should have a single source
        list<Source__c> listSrc = segment.getSObjects('Sources__r');
        
        if (listSrc.size() > 0) {
            Source__c src = listSrc[0];
            // if this member refers to this source
            if (member.Sources__c != null && member.Sources__c.contains(src.Id))
                // then it is to be included.
                return !src.Exclude__c;
        }

        // not a leaf node, so recursively call on all child segments
        list<Segment__c> listSegChildren = segment.getSObjects('Segments__r');
        boolean isAnd = segment.Operation__c == 'AND';
        boolean includeMember = isAnd;  // and requires starting with true, or requires starting with false.
        
        for (Segment__c seg : listSegChildren) {
            boolean include = includeMemberInSegmentTree(member, seg);
            if (isAnd) {
                if (!include)
                    return false; // we can short circuit in this case!
            } else { // Or
                if (include)
                    return true; // we can short circuit in this case!
            }            
        }
        
        // finished calling all children, and we didn't short circuit, 
        // so we know what to return given our Operation.
        // And with no short circuiting means true
        // Or with no short circuiting means false
        return (isAnd);
        
    }
    

}