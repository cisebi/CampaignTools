public abstract class CampaignListSegment {
    private Id segmentId;
    private Id rootSegmentId;
    private Id parentId;

    public abstract CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode();

    public CampaignListSegment(Id segmentId, Id rootSegmentId, Id parentId) {
        this.segmentId = segmentId;
        this.rootSegmentId = rootSegmentId;
        this.parentId = parentId;
    }

    public Id getId() {
        return segmentId;
    }

    public class AndSegment extends CampaignListSegment {
        public AndSegment(Id segmentId, Id rootSegmentId, Id parentId) {
            super(segmentId, rootSegmentId, parentId);
        }

        public override CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode() {
            return new CampaignListCriteria.AndNode(parentId);
        }
    }

    public class OrSegment extends CampaignListSegment {
        public OrSegment(Id segmentId, Id rootSegmentId, Id parentId) {
            super(segmentId, rootSegmentId, parentId);
        }

        public override CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode() {
            return new CampaignListCriteria.OrNode(parentId);
        }
    }

    public abstract class SourceSegment extends CampaignListSegment {
        private Id sourceId;
        private Boolean isExclusion;

        public SourceSegment(Id segmentId, Id rootSegmentId, Id parentId, Id sourceId, Boolean isExclusion) {
            super(segmentId, rootSegmentId, parentId);
            this.sourceId = sourceId;
            this.isExclusion = isExclusion;
        }

        public override CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode() {
            return new CampaignListCriteria.SourceNode(parentId, sourceId, isExclusion);
        }

        public String getSourceName() {
            return CampaignListSegmentMapper.getSourceNameById(sourceId);
        }

        public abstract BatchableSequence.Batch getBatchProcessor();
    }

    public class CampaignSourceSegment extends SourceSegment {
        public CampaignSourceSegment(Id segmentId, Id rootSegmentId, Id parentId, Id sourceId, Boolean isExclusion) {
            super(segmentId, rootSegmentId, parentId, sourceId, isExclusion);
        }

        public override BatchableSequence.Batch getBatchProcessor() {
            CampaignListFromCampaignBatch batch = new CampaignListFromCampaignBatch(
                rootSegmentId,
                sourceId,
                getSourceName()
            );

            batch.setScope(10000);

            return batch;
        }
    }

    public class ReportSourceSegment extends SourceSegment {
        private String columnName;

        public ReportSourceSegment(Id segmentId, Id rootSegmentId, Id parentId, Id sourceId, Boolean isExclusion, String columnName) {
            super(segmentId, rootSegmentId, parentId, sourceId, isExclusion);
            this.columnName = columnName;
        }

        public override BatchableSequence.Batch getBatchProcessor() {
            CampaignListFromReportBatch batch = new CampaignListFromReportBatch(
                rootSegmentId,
                sourceId,
                columnName,
                getSourceName()
            );

            batch.setScope(2000);

            return batch;
        }
    }
}