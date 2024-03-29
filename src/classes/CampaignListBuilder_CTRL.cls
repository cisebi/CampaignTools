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
    * Neither the name of the Salesforce.org nor the names of
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
* @date 2015
*
* @group CampaignTools
*
* @description Apex controller for the Lightning CampaignListBuilder app.
*
*/

public with sharing class CampaignListBuilder_CTRL {
    @AuraEnabled
    public static String getSerializedSegmentTree(Id rootSegmentId) {
        CampaignList.SegmentMapper mapper = new CampaignListSegmentMapper();
        return JSON.serialize(mapper.getSegmentTreeByRootId(rootSegmentId));
    }

    @AuraEnabled
    public static boolean saveCSegmentTree(ID campaignId, string csegRoot) {
        CampaignList.SegmentMapper mapper = new CampaignListSegmentMapper();
        CampaignList.Segment segmentTree = mapper.deserializeSegmentFromJSON(csegRoot);
        Id rootSegmentId = mapper.upsertSegmentTreeByRootSegment(segmentTree);
        update new Campaign(Id = campaignId, Campaign_List__c = rootSegmentId);
        return true;
    }

    @AuraEnabled
    public static Campaign getCampaign(ID campaignId) {
        if (campaignId == null)
            return null;
        return [select Id, Name, Campaign_List__c from Campaign where Id = :campaignId];
    }

    @AuraEnabled
    public static Map<String, String> getReportIdColumns(Id reportId) {
        try {
            CampaignList.ReportService service = CampaignList.getReportService();
            return service.getIdColumns(reportId);
        } catch (Exception e) {
            throw new NoColumnsException();
        }
    }

    public class NoColumnsException extends Exception {}
}