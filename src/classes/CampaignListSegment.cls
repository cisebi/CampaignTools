/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A model class that represents a single "segment" of a campaign
 * list.  A "segment" of a campaign list is one part of the criteria that
 * defines the campaign list.
 */
public abstract class CampaignListSegment {
    /** @description This segment's id */
    private Id segmentId;

    /** @description The id of the "campaign list" this segment belongs to */
    private Id rootSegmentId;

    /**
     * @description The immediate parent of this segment in the segment tree
     */
    private Id parentId;

    /**
     * @description Get a CriteriaTreeNode that corresponds to this segment.
     * The CriteriaTreeNode differs from a CampaignListSegment in that the
     * CriteriaListSegment is a data model class that corresponds to a single
     * Segment__c sObject, but a CriteriaTreeNode is an object intended to
     * exist as part of the criteria tree in a CampaignListCriteria instance.
     */
    public abstract CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode();

    /**
     * @description Construct a CampaignListSegment
     * @param segmentId The id of this segment
     * @param rootSegmentId The id of the "campaign list" this segment belongs to
     * @param parentId The immediate parent of this segment
     */
    public CampaignListSegment(Id segmentId, Id rootSegmentId, Id parentId) {
        this.segmentId = segmentId;
        this.rootSegmentId = rootSegmentId;
        this.parentId = parentId;
    }

    /**
     * @description get this segment's id
     * @return Id
     */
    public Id getId() {
        return segmentId;
    }

    /**
     * @description get "campaign list" id this segment belongs to
     * @return Id
     */
    public Id getRootSegmentId() {
        return rootSegmentId;
    }

    /**
     * @description get this segment's parent id
     * @return Id
     */
    public Id getParentId() {
        return parentId;
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This is a specific type of CampaignListSegment that
     * represents an 'AND' segment
     */
    public class AndSegment extends CampaignListSegment {
        /**
         * @description Construct an AndSegment
         * @param segmentId The id of this segment
         * @param rootSegmentId The id of the "campaign list" this segment belongs to
         * @param parentId The immediate parent of this segment
         */
        public AndSegment(Id segmentId, Id rootSegmentId, Id parentId) {
            super(segmentId, rootSegmentId, parentId);
        }

        /**
         * @description Get a CriteriaTreeNode that corresponds to this
         * AndSegment.  In this case, a CampaignListCriteria.AndNode.
         *
         * @return CampaignListCriteria.CriteriaTreeNode
         */
        public override CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode() {
            return new CampaignListCriteria.AndNode(parentId);
        }
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This is a specific type of CampaignListSegment that
     * represents an 'OR' segment
     */
    public class OrSegment extends CampaignListSegment {
        /**
         * @description Construct an OrSegment
         * @param segmentId The id of this segment
         * @param rootSegmentId The id of the "campaign list" this segment belongs to
         * @param parentId The immediate parent of this segment
         */
        public OrSegment(Id segmentId, Id rootSegmentId, Id parentId) {
            super(segmentId, rootSegmentId, parentId);
        }

        /**
         * @description Get a CriteriaTreeNode that corresponds to this
         * OrSegment.  In this case, a CampaignListCriteria.OrNode.
         *
         * @return CampaignListCriteria.CriteriaTreeNode
         */
        public override CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode() {
            return new CampaignListCriteria.OrNode(parentId);
        }
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This is a specific type of CampaignListSegment that
     * represents a 'SOURCE' segment
     */
    public abstract class SourceSegment extends CampaignListSegment {
        /**
         * @description The id of the source this segment corresponds to, i.e.
         * a Report id or a Campaign id, etc.
         */
        private Id sourceId;

        /**
         * @description True if this source is intended to be used to exclude
         * members from the campaign list.  False, otherwise.
         */
        private Boolean isExclusion;

        /**
         * @description The CampaignListSegmentMapper to use for retrieving
         * this source's name
         */
        @TestVisible
        private CampaignListSegmentMapper.MapperInterface segmentMapper;

        /**
         * @description Construct a SourceSegment
         * @param segmentId The id of this segment
         * @param rootSegmentId The id of the "campaign list" this segment belongs to
         * @param parentId The immediate parent of this segment
         */
        public SourceSegment(Id segmentId, Id rootSegmentId, Id parentId, Id sourceId, Boolean isExclusion) {
            super(segmentId, rootSegmentId, parentId);
            this.sourceId = sourceId;
            this.isExclusion = isExclusion;
            this.segmentMapper = new CampaignListSegmentMapper();
        }

        /**
         * @description get the id of the source this segment corresponds to
         * @return Id
         */
        public Id getSourceId() {
            return sourceId;
        }

        /**
         * @description Is this source segment intended to exclude members
         * found in the source?
         *
         * @return Boolean
         */
        public Boolean isExclusion() {
            return isExclusion;
        }

        /**
         * @description Get a CriteriaTreeNode that corresponds to this
         * OrSegment.  In this case, a CampaignListCriteria.SourceNode.
         *
         * @return CampaignListCriteria.CriteriaTreeNode
         */
        public override CampaignListCriteria.CriteriaTreeNode getCriteriaTreeNode() {
            return new CampaignListCriteria.SourceNode(parentId, sourceId, isExclusion);
        }

        /**
         * @description Get the name of this source.  Note that this may
         * execute a SOQL query to find the name of this source using the
         * sourceId.
         *
         * @return String
         */
        public String getSourceName() {
            return segmentMapper.getSourceNameById(sourceId);
        }

        /**
         * @description Get an appropriate BatchableSequence.Batch class that
         * can be executed to retrieve CampaignListMembers from this source and
         * persist those members to the database
         */
        public abstract BatchableSequence.Batch getBatchProcessor();
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This is a specific type of SourceSegment that represents a
     * Campaign 'SOURCE' segment
     */
    public class CampaignSourceSegment extends SourceSegment {
        /**
         * @description Construct a CampaignSourceSegment
         * @param segmentId The id of this segment
         * @param rootSegmentId The id of the "campaign list" this segment belongs to
         * @param parentId The immediate parent of this segment
         * @param sourceId The id of the source Campaign
         * @param isExclusion True if this source is intended to exclude members that are found in the given campaign.  False, otherwise.
         */
        public CampaignSourceSegment(Id segmentId, Id rootSegmentId, Id parentId, Id sourceId, Boolean isExclusion) {
            super(segmentId, rootSegmentId, parentId, sourceId, isExclusion);
        }

        /**
         * @description Get an appropriate BatchableSequence.Batch class that
         * can be executed to retrieve CampaignListMembers from this source and
         * persist those members to the database.  In this case, it will return
         * a BatchableSequence.Batch class appropriate for retrieving
         * CampaignListMembers from an existing Campaign.
         */
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

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This is a specific type of SourceSegment that represents a
     * Report 'SOURCE' segment
     */
    public class ReportSourceSegment extends SourceSegment {
        /**
         * @description the name of the column in the source report that holds
         * the id of the related Contact or Lead
         */
        private String columnName;

        /**
         * @description Construct a ReportSourceSegment
         * @param segmentId The id of this segment
         * @param rootSegmentId The id of the "campaign list" this segment belongs to
         * @param parentId The immediate parent of this segment
         * @param sourceId The id of the source Report
         * @param isExclusion True if this source is intended to exclude members that are found in the given report.  False, otherwise.
         * @param columnName the name of the column in the source report that holds the id of the related Contact or Lead
         */
        public ReportSourceSegment(Id segmentId, Id rootSegmentId, Id parentId, Id sourceId, Boolean isExclusion, String columnName) {
            super(segmentId, rootSegmentId, parentId, sourceId, isExclusion);
            this.columnName = columnName;
        }

        /**
         * @description Get the column name of the report that this source
         * segment is intending to use to retrieve values from the report
         *
         * @return String
         */
        public String getColumnName() {
           return columnName;
        }

        /**
         * @description Get an appropriate BatchableSequence.Batch class that
         * can be executed to retrieve CampaignListMembers from this source and
         * persist those members to the database.  In this case, it will return
         * a BatchableSequence.Batch class appropriate for retrieving
         * CampaignListMembers from a Report.
         */
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