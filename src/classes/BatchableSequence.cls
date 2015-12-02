public class BatchableSequence {
    private List<Batch> batches = new List<Batch>();

    public Batch add(Batch b) {
        if (null == b.getScope()) {
            b.setScope(200);
        }
        if (!batches.isEmpty()) {
            batches.get(batches.size() - 1).setNext(b);
        }
        batches.add(b);
        return b;
    }

    public Batch add(Batch b, Integer scope) {
        b.setScope(scope);
        return add(b);
    }

    public Id run() {
        if (!batches.isEmpty()) {
            return batches.get(0).executeBatch();
        }
        return null; // @todo throw exception?
    }

    public abstract class Batch {
        private Batch next;
        private Integer scope;

        public virtual void finish(Database.BatchableContext bc) {
            if (null != next) {
                next.executeBatch();
            }
        }

        public void setScope(Integer scope) {
            this.scope = scope;
        }

        public Integer getScope() {
            return scope;
        }

        public void setNext(Batch next) {
            this.next = next;
        }

        public abstract Id executeBatch();
    }
}