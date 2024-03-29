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
 * @author Salesforce.org
 * @group CampaignTools
 * @description Batch process for populating a campaign with CampaignMembers
 * from a campaign list's sources that match the campaign list's inclusion
 * criteria
 */
public class CampaignListToCampaignBatch extends BatchableSequence.Batch implements Database.Batchable<sObject> {
    /** @description The id of the Campaign to populate */
    @TestVisible
    private Id campaignId;

    /** @description The "campaign list" root segment */
    @TestVisible
    private CampaignList.Segment rootSegment;

    /**
     * @description Construct the batch process to populate the given campaign
     * with CampaignMembers from the given campaign list's sources that match
     * the given CampaignListCriteria
     *
     * @param campaignId The id of the Campaign to populate
     * @param rootSegment The "campaign list" root segment
     */
    public CampaignListToCampaignBatch(Id campaignId, CampaignList.Segment rootSegment) {
        this.campaignId = campaignId;
        this.rootSegment = rootSegment;
    }

    /**
     * @description Implementation of start() from Database.Batchable
     * interface.
     *
     * @return Database.QueryLocator The Member__c records from the specified campaign list
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id rootSegmentId = rootSegment.getId();
        return Database.getQueryLocator(
            'SELECT Contact__c, Lead__c, Root_Segment__c, Sources__c, Source_Names__c FROM Member__c WHERE Root_Segment__c = :rootSegmentId'
        );
    }

    /**
     * @description Implementation of execute() from Database.Batchable.
     * Creates CampaignMembers from the Member__c sObjects that have been
     * prepared for this campaign list.  Each member will be checked to see if
     * it meets the criteria to be included in the campaign, and if so an
     * appropriate CampaignMember record will be created.
     *
     * @return void
     */
    public void execute(Database.BatchableContext bc, List<Member__c> scope) {
        List<CampaignList.Member> eligibleMembers = new List<CampaignList.Member>();

        for (Member__c m : scope) {
            CampaignList.Member member = new CampaignListMember(m);
            if (member.meetsCriteria(rootSegment)) {
                eligibleMembers.add(member);
            }
        }

        CampaignList.getMemberMapper().addMembersToCampaign(eligibleMembers, campaignId);
    }

    /**
     * @description Implementation of finish() from Database.Batchable
     * interface.  This will call BatachableSequence's finish() method and then
     * update the specified campaign's status to indicate that it was
     * successfully populated from the specified campaign list.
    *
    * @param bc The BatchableContext for this batch
    * @return void
    */
    public override void finish(Database.BatchableContext bc) {
        super.finish(bc);
        try {
            CampaignList.getService().updateCampaignStatus(
                campaignId,
                CampaignList.UpdateStatus.SUCCESS
            );

            Mutex.MutexInterface m = CampaignList.getMutexFactory().create(campaignId, Campaign.Campaign_List_Mutex__c);
            Boolean lockReleased = m.releaseLock();

            if (!lockReleased) {
                throw new CouldNotReleaseLockException(
                    String.format(
                        Label.CampaignToolsReleaseLockException,
                        new List<String>{campaignId}
                    )
                );
            }

        } catch (Exception e) {
            throw new CouldNotUpdateCampaignException(
                String.format(
                    Label.CampaignToolsCantFinishUpdateException,
                    new List<String>{campaignId}
                ),
                e
            );
        }

    }

    /**
     * @description This will cause this batch to be executed, i.e.,
     * Database.executeBatch() will be called with this batch as the batch to
     * execute and this batch's scope.
     *
     * @return Id The id of the AsyncApexJob returned by Database.executeBatch()
     */
    public override Id executeBatch() {
        return Database.executeBatch(this, getScope());
    }

    public virtual class CustomException extends Exception {}
    public class CouldNotReleaseLockException extends CustomException {}
    public class CouldNotUpdateCampaignException extends CustomException {}
}