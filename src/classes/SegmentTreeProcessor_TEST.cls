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
* @description test code for the SegmentTreeProcessor class
*
*/
@isTest
private with sharing class SegmentTreeProcessor_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*********************************************************************************************************
    * @description test processing a single leaf tree where the source should be included; 
    */	
    static testMethod void testSingleLeafIn() {
        if (strTestOnly != '*' && strTestOnly != 'testSingleLeafIn') return;
        
        Segment__c seg = new Segment__c();
        seg.Exclude_Source__c = false;
        seg.Source_ID__c = 'foo';
        seg.Source_Type__c = 'Campaign';
        insert seg;
        
        list<Member__c> listMember = new list<Member__c>();
        Member__c member = new Member__c();
        member.Root_Segment__c = seg.Id;
        member.Sources__c = seg.Id;
        listMember.add(member);
        insert listMember;
        
        CSegment cseg = new CSegment();
        cseg.Segment = seg;
        
        SegmentTreeProcessor.processSegmentTree(cseg, listMember);
        system.assertEquals(true, listMember[0].Include_in_List__c);
    }

    /*********************************************************************************************************
    * @description test processing a single leaf tree where the source should not be included; 
    */  
    static testMethod void testSingleLeafOut() {
        if (strTestOnly != '*' && strTestOnly != 'testSingleLeafOut') return;
        
        Segment__c seg = new Segment__c();
        seg.Exclude_Source__c = false;
        seg.Source_ID__c = 'foo';
        seg.Source_Type__c = 'Campaign';
        insert seg;
        
        list<Member__c> listMember = new list<Member__c>();
        Member__c member = new Member__c();
        member.Root_Segment__c = seg.Id;
        member.Sources__c = 'bar';
        listMember.add(member);
        insert listMember;
        
        CSegment cseg = new CSegment();
        cseg.Segment = seg;
        
        SegmentTreeProcessor.processSegmentTree(cseg, listMember);
        system.assertEquals(false, listMember[0].Include_in_List__c);
    }

}