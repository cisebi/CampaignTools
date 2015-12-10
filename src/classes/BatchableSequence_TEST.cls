@isTest
private class BatchableSequence_TEST {
    private static testMethod void testAddBatchWithoutScopeAddsDefaultScope() {
        BatchableSequence bs = new BatchableSequence();
        ConcreteBatch batch = new ConcreteBatch();

        bs.add(batch);

        System.assertEquals(200, batch.getScope());
    }

    private static testMethod void testAddBatchWithoutScopeHonorsExistingScope() {
        BatchableSequence bs = new BatchableSequence();
        ConcreteBatch batch = new ConcreteBatch();
        batch.setScope(999);

        bs.add(batch);

        System.assertEquals(999, batch.getScope());
    }

    private static testMethod void testAddBatchWithScopeOverridesExistingScope() {
        BatchableSequence bs = new BatchableSequence();
        ConcreteBatch batch = new ConcreteBatch();
        batch.setScope(999);

        bs.add(batch, 222);

        System.assertEquals(222, batch.getScope());
    }

    private static testMethod void testAddSecondBatchLinksToPreviousBatch() {
        BatchableSequence bs = new BatchableSequence();
        ConcreteBatch firstBatch = new ConcreteBatch();
        ConcreteBatch secondBatch = new ConcreteBatch();

        bs.add(firstBatch);
        bs.add(secondBatch);

        System.assertEquals(secondBatch, firstBatch.next);
    }

    private static testMethod void testGetScopeReturnsNullIfNoScopeSet() {
        ConcreteBatch batch = new ConcreteBatch();
        System.assertEquals(null, batch.getScope());
    }

    private static testMethod void testGetScopeReturnsScopeIfScopeSet() {
        ConcreteBatch batch = new ConcreteBatch();
        batch.setScope(999);
        System.assertEquals(999, batch.getScope());
    }

    private static testMethod void testFinishWithNoNextBatchIsNoOp() {
        ConcreteBatch batch = new ConcreteBatch();

        try {
            batch.finish(null);
        } catch (Exception e) {
            System.assert(
                false,
                'Finish with no next batch threw an exception: ' + e.getMessage()
            );
        }
    }

    private static testMethod void testFinishWillRunNextBatch() {
        ConcreteBatch firstBatch = new ConcreteBatch();
        ConcreteBatch secondBatch = new ConcreteBatch();

        firstBatch.setNext(secondBatch);

        firstBatch.finish(null);

        System.assertEquals(0, firstBatch.executionCount);
        System.assertEquals(1, secondBatch.executionCount);
    }

    private static testMethod void testExecuteBatchReturnsAsyncApexJobId() {
        ConcreteBatch batch = new ConcreteBatch();
        Id actualId = batch.executeBatch();
        System.assertEquals(batch.asyncApexJobId, actualId);
    }

    private static testMethod void testBatchableSequenceRunExecutesFirstBatch() {
        BatchableSequence bs = new BatchableSequence();
        ConcreteBatch batch = new ConcreteBatch();

        bs.add(batch);
        bs.run();

        System.assertEquals(1, batch.executionCount);
    }

    private static testMethod void testBatchableSequenceReturnsAsyncApexJobIdFromRun() {
        BatchableSequence bs = new BatchableSequence();
        ConcreteBatch batch = new ConcreteBatch();

        bs.add(batch);
        Id actualId = bs.run();

        System.assertEquals(batch.asyncApexJobId, actualId);
    }

    private static testMethod void testBatchableSequenceReturnsNullFromRunWhenEmpty() {
        BatchableSequence bs = new BatchableSequence();
        System.assertEquals(null, bs.run());
    }

    private class ConcreteBatch extends BatchableSequence.Batch {
        public Integer executionCount = 0;
        public Id asyncApexJobId = AsyncApexJob.sObjectType.getDescribe().getKeyPrefix() + '000000000001';

        public override Id executeBatch() {
            executionCount++;
            return asyncApexJobId;
        }
    }
}