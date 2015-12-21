@isTest
private class CampaignListSegment_TEST2 {
    private static Integer nextId = 1;

    private static Id getNextId(Schema.SObjectType sObjectType) {
        String id_x = '' + nextId++;
        while (id_x.length() < 12) {
            id_x = '0' + id_x;
        }
        id_x = sObjectType.getDescribe().getKeyPrefix() + id_x;
        return id_x;
    }

    private static testMethod void testCriteriaWithSingleSource() {
        /*
         * Criteria tree as s-expression:
         * (SOURCE A)
         */

        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            null,
            sourceAId,
            false
        );

        CampaignListSegment rootSegment = sourceASegment;

        /*
         * Test members:
         * (), (A), (B), (A, B)
         *
         * Expected to meet criteria:
         * (A), (A, B)
         *
         * Expected to not meet criteria:
         * (), (B)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            null,
            null,
            null
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B)')));
    }

    private static testMethod void testCriteriaWithSingleSourceExclusion() {
        /*
         * Criteria tree as s-expression:
         * (NOT (SOURCE A))
         */

        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            null,
            sourceAId,
            true
        );

        CampaignListSegment rootSegment = sourceASegment;

        /*
         * Test members:
         * (), (A), (B), (A, B)
         *
         * Expected to meet criteria:
         * (), (B)
         *
         * Expected to not meet criteria:
         * (A), (A, B)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            null,
            null,
            null
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, B)')));
    }

    private static testMethod void testCriteriaWithAndRootNodeAndTwoSources() {
        /*
         * Criteria tree as s-expression:
         * (AND
         *     (SOURCE A)
         *     (SOURCE B)
         * )
         */

        Id andSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);
        Id sourceCId = getNextId(Campaign.sObjectType);

        CampaignListSegment andSegment = new CampaignListSegment.AndSegment(
            andSegmentId,
            null,
            null
        );

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            andSegmentId,
            sourceAId,
            false
        );

        CampaignListSegment sourceBSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceBSegmentId,
            null,
            andSegmentId,
            sourceBId,
            false
        );

        CampaignListSegment rootSegment = andSegment;
        rootSegment.addChild(sourceASegment);
        rootSegment.addChild(sourceBSegment);

        /*
         * Test members:
         * (), (A), (B), (C), (A, B), (A, C), (B, C), (A, B, C)
         *
         * Expected to meet criteria:
         * (A, B), (A, B, C)
         *
         * Expected to not meet criteria:
         * (), (A), (B), (C), (A, C), (B, C)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            sourceCId,
            null,
            null
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, C)')));

    }

    private static testMethod void testCriteriaWithOrRootNodeAndTwoSources() {
        /*
         * Criteria tree as s-expression:
         * (OR
         *     (SOURCE A)
         *     (SOURCE B)
         * )
         */

        Id orSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);
        Id sourceCId = getNextId(Campaign.sObjectType);

        CampaignListSegment orSegment = new CampaignListSegment.OrSegment(
            orSegmentId,
            null,
            null
        );

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            orSegmentId,
            sourceAId,
            false
        );

        CampaignListSegment sourceBSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceBSegmentId,
            null,
            orSegmentId,
            sourceBId,
            false
        );

        CampaignListSegment rootSegment = orSegment;
        rootSegment.addChild(sourceASegment);
        rootSegment.addChild(sourceBSegment);

        /*
         * Test members:
         * (), (A), (B), (C), (A, B), (A, C), (B, C), (A, B, C)
         *
         * Expected to meet criteria:
         * (A), (B), (A, B), (A, C), (B, C), (A, B, C)
         *
         * Expected to not meet criteria:
         * (), (C)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            sourceCId,
            null,
            null
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B, C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(C)')));
    }

    private static testMethod void testCriteriaWithAndRootNodeAndTwoSourcesWithOneExclusion() {
        /*
         * Criteria tree as s-expression:
         * (AND
         *     (NOT (SOURCE A))
         *     (SOURCE B)
         * )
         */

        Id andSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);
        Id sourceCId = getNextId(Campaign.sObjectType);

        CampaignListSegment andSegment = new CampaignListSegment.AndSegment(
            andSegmentId,
            null,
            null
        );

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            andSegmentId,
            sourceAId,
            true
        );

        CampaignListSegment sourceBSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceBSegmentId,
            null,
            andSegmentId,
            sourceBId,
            false
        );

        CampaignListSegment rootSegment = andSegment;
        rootSegment.addChild(sourceASegment);
        rootSegment.addChild(sourceBSegment);

        /*
         * Test members:
         * (), (A), (B), (C), (A, B), (A, C), (B, C), (A, B, C)
         *
         * Expected to meet criteria:
         * (B), (B, C)
         *
         * Expected to not meet criteria:
         * (), (A), (C), (A, B), (A, C), (A, B, C)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            sourceCId,
            null,
            null
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, B)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, B, C)')));
    }

    private static testMethod void testCriteriaWithOrRootNodeAndTwoSourcesWithOneExclusion() {
        /*
         * Criteria tree as s-expression:
         * (OR
         *     (NOT (SOURCE A))
         *     (SOURCE B)
         * )
         */

        Id orSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);
        Id sourceCId = getNextId(Campaign.sObjectType);

        CampaignListSegment orSegment = new CampaignListSegment.OrSegment(
            orSegmentId,
            null,
            null
        );

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            orSegmentId,
            sourceAId,
            true
        );

        CampaignListSegment sourceBSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceBSegmentId,
            null,
            orSegmentId,
            sourceBId,
            false
        );

        CampaignListSegment rootSegment = orSegment;
        rootSegment.addChild(sourceASegment);
        rootSegment.addChild(sourceBSegment);

        /*
         * Test members:
         * (), (A), (B), (C), (A, B), (A, C), (B, C), (A, B, C)
         *
         * Expected to meet criteria:
         * (), (B), (C), (A, B), (B, C), (A, B, C)
         *
         * Expected to not meet criteria:
         * (A), (A, C)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            sourceCId,
            null,
            null
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(B, C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, C)')));
    }

    private static testMethod void testCriteriaWithComplexCriteriaTree() {
        /*
         * Criteria tree as s-expression:
         * (AND
         *     (OR
         *         (SOURCE A)
         *         (NOT (SOURCE B))
         *     )
         *     (OR
         *         (SOURCE C)
         *         (SOURCE D)
         *     )
         * )
         */

        Id andSegmentId = getNextId(Segment__c.sObjectType);
        Id orSegment1Id = getNextId(Segment__c.sObjectType);
        Id orSegment2Id = getNextId(Segment__c.sObjectType);
        Id sourceASegmentId = getNextId(Segment__c.sObjectType);
        Id sourceAId = getNextId(Campaign.sObjectType);
        Id sourceBSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceBId = getNextId(Campaign.sObjectType);
        Id sourceCSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceCId = getNextId(Campaign.sObjectType);
        Id sourceDSegmentId = getNextId(Segment__c.sObjectType);
        Id sourceDId = getNextId(Campaign.sObjectType);
        Id sourceEId = getNextId(Campaign.sObjectType);

        CampaignListSegment andSegment = new CampaignListSegment.AndSegment(
            andSegmentId,
            null,
            null
        );

        CampaignListSegment orSegment1 = new CampaignListSegment.OrSegment(
            orSegment1Id,
            null,
            andSegmentId
        );

        CampaignListSegment orSegment2 = new CampaignListSegment.OrSegment(
            orSegment2Id,
            null,
            andSegmentId
        );

        CampaignListSegment sourceASegment = new CampaignListSegment.CampaignSourceSegment(
            sourceASegmentId,
            null,
            orSegment1Id,
            sourceAId,
            false
        );

        CampaignListSegment sourceBSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceBSegmentId,
            null,
            orSegment1Id,
            sourceBId,
            true
        );

        CampaignListSegment sourceCSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceCSegmentId,
            null,
            orSegment2Id,
            sourceCId,
            false
        );

        CampaignListSegment sourceDSegment = new CampaignListSegment.CampaignSourceSegment(
            sourceDSegmentId,
            null,
            orSegment2Id,
            sourceDId,
            false
        );

        CampaignListSegment rootSegment = andSegment;
        rootSegment.addChild(orSegment1);
        orSegment1.addChild(sourceASegment);
        orSegment1.addChild(sourceBSegment);
        rootSegment.addChild(orSegment2);
        orSegment2.addChild(sourceCSegment);
        orSegment2.addChild(sourceDSegment);

        /*
         * Test members:
         * (), (A), (B), (A, B), (C), (A, C), (B, C), (A, B, C),
         * (D), (A, D), (B, D), (A, B, D), (C, D), (A, C, D), (B, C, D), (A, B, C, D),
         * (E), (A, E), (B, E), (A, B, E), (C, E), (A, C, E), (B, C, E), (A, B, C, E),
         * (D, E), (A, D, E), (B, D, E), (A, B, D, E), (C, D, E), (A, C, D, E), (B, C, D, E), (A, B, C, D, E)
         *
         * Expected to meet criteria:
         * (C), (A, C), (A, B, C),
         * (D), (A, D), (A, B, D), (C, D), (A, C, D), (A, B, C, D),
         * (C, E), (A, C, E), (A, B, C, E),
         * (D, E), (A, D, E), (A, B, D, E), (C, D, E), (A, C, D, E), (A, B, C, D, E)
         *
         * Expected to not meet criteria:
         * (), (A), (B), (A, B), (B, C),
         * (B, D), (B, C, D),
         * (E), (A, E), (B, E), (A, B, E), (B, C, E),
         * (B, D, E), (B, C, D, E)
         */

        Map<String, CampaignListMember> members = getTestMembersWithSources(
            sourceAId,
            sourceBId,
            sourceCId,
            sourceDId,
            sourceEId
        );

        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(D)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, D)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, D)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(C, D)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, C, D)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C, D)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(C, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, C, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(D, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, D, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, D, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(C, D, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, C, D, E)')));
        System.assertEquals(true, rootSegment.meetsCriteria(members.get('(A, B, C, D, E)')));

        System.assertEquals(false, rootSegment.meetsCriteria(members.get('()')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, B)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, C)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, D)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, C, D)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(E)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, E)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, E)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(A, B, E)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, C, E)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, D, E)')));
        System.assertEquals(false, rootSegment.meetsCriteria(members.get('(B, C, D, E)')));
    }

    private static Map<String, CampaignListMember> getTestMembersWithSources(Id A, Id B, Id C, Id D, Id E) {
        Map<String, CampaignListMember> members = new Map<String, CampaignListMember>();

        members.put('()', getTestMemberWithSources(null, null, null, null, null));

        if (null != A) {
            members.put('(A)', getTestMemberWithSources(A, null, null, null, null));
            if (null != B) {
                members.put('(B)',    getTestMemberWithSources(null, B, null, null, null));
                members.put('(A, B)', getTestMemberWithSources(   A, B, null, null, null));
                if (null != C) {
                    members.put('(C)',       getTestMemberWithSources(null, null, C, null, null));
                    members.put('(A, C)',    getTestMemberWithSources(   A, null, C, null, null));
                    members.put('(B, C)',    getTestMemberWithSources(null,    B, C, null, null));
                    members.put('(A, B, C)', getTestMemberWithSources(   A,    B, C, null, null));
                }
                if (null != D) {
                    members.put('(D)',          getTestMemberWithSources(null, null, null, D, null));
                    members.put('(A, D)',       getTestMemberWithSources(   A, null, null, D, null));
                    members.put('(B, D)',       getTestMemberWithSources(null,    B, null, D, null));
                    members.put('(A, B, D)',    getTestMemberWithSources(   A,    B, null, D, null));
                    members.put('(C, D)',       getTestMemberWithSources(null, null,    C, D, null));
                    members.put('(A, C, D)',    getTestMemberWithSources(   A, null,    C, D, null));
                    members.put('(B, C, D)',    getTestMemberWithSources(null,    B,    C, D, null));
                    members.put('(A, B, C, D)', getTestMemberWithSources(   A,    B,    C, D, null));
                }
                if (null != E) {
                    members.put('(E)',             getTestMemberWithSources(null, null, null, null, E));
                    members.put('(A, E)',          getTestMemberWithSources(   A, null, null, null, E));
                    members.put('(B, E)',          getTestMemberWithSources(null,    B, null, null, E));
                    members.put('(A, B, E)',       getTestMemberWithSources(   A,    B, null, null, E));
                    members.put('(C, E)',          getTestMemberWithSources(null, null,    C, null, E));
                    members.put('(A, C, E)',       getTestMemberWithSources(   A, null,    C, null, E));
                    members.put('(B, C, E)',       getTestMemberWithSources(null,    B,    C, null, E));
                    members.put('(A, B, C, E)',    getTestMemberWithSources(   A,    B,    C, null, E));
                    members.put('(D, E)',          getTestMemberWithSources(null, null, null,    D, E));
                    members.put('(A, D, E)',       getTestMemberWithSources(   A, null, null,    D, E));
                    members.put('(B, D, E)',       getTestMemberWithSources(null,    B, null,    D, E));
                    members.put('(A, B, D, E)',    getTestMemberWithSources(   A,    B, null,    D, E));
                    members.put('(C, D, E)',       getTestMemberWithSources(null, null,    C,    D, E));
                    members.put('(A, C, D, E)',    getTestMemberWithSources(   A, null,    C,    D, E));
                    members.put('(B, C, D, E)',    getTestMemberWithSources(null,    B,    C,    D, E));
                    members.put('(A, B, C, D, E)', getTestMemberWithSources(   A,    B,    C,    D, E));
                }
            }
        }
        return members;
    }

    private static CampaignListMember getTestMemberWithSources(Id A, Id B, Id C, Id D, Id E) {
        CampaignListMember member = new CampaignListMember(null, null);
        if (null != A) {
            member.addSource(A, 'A');
        }
        if (null != B) {
            member.addSource(B, 'B');
        }
        if (null != C) {
            member.addSource(C, 'C');
        }
        if (null != D) {
            member.addSource(D, 'D');
        }
        if (null != E) {
            member.addSource(E, 'E');
        }
        return member;
    }
}