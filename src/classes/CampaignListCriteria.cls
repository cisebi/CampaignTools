/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description This represents the criteria used to determine whether a
 * Contact or a Lead should be included in a Campaign.
 */
public class CampaignListCriteria implements Interface_x {
    public interface Interface_x {
        Boolean meetsCriteria(CampaignListMember m);
    }

    /** @description The root node of the criteria tree */
    private CriteriaTreeNode rootNode;

    /**
     * @description Construct the campaign list criteria from a list of
     * segments.
     *
     * @param segments The list of segments that make up the campaign list criteria.
     */
    public CampaignListCriteria(List<CampaignListSegment> segments) {
        Map<Id, CriteriaTreeNode> nodes = new Map<Id, CriteriaTreeNode>();

        for (CampaignListSegment segment : segments) {
            CriteriaTreeNode node = segment.getCriteriaTreeNode();
            nodes.put(segment.getId(), node);
        }

        for (CriteriaTreeNode node : nodes.values()) {
            Id pid = node.getParentId();

            if (null == pid) {
                rootNode = node;
            } else if (nodes.containsKey(pid)) {
                nodes.get(pid).addTerm(node);
            }
        }
    }

    /**
     * @description Given a CampaignListMember, determine whether or not that
     * member meets this campaign list criteria.
     *
     * @return Boolean (true if the CampaignListMember meets the criteria for inclusion in a campaign, false otherwise)
     */
    public Boolean meetsCriteria(CampaignListMember m) {
        return rootNode.meetsCriteria(m);
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This represents a single node in a tree of criteria.
     * Campaign list criteria is represented as a tree, because it allows the
     * user to specify which sources to use for Contacts or Leads and to
     * combine them using nested logical operators.  For example, include
     * Contacts or Leads if they come from (source1 AND source2) OR (source2
     * AND source3) AND (source1) AND NOT(source4).
     */
    public abstract class CriteriaTreeNode {

        /**
         * @description The id of the parent node of this node.  All nodes
         * except the root node must have a parent id.
         */
        private Id parentId;

        /**
         * @description For nodes that act as logical groupings, i.e. 'And' and
         * 'Or' nodes, this represents the terms inside that grouping.
         */
        private List<CriteriaTreeNode> terms = new List<CriteriaTreeNode>();

        /**
         * @description Add a term to this grouping node.
         * @param term The node to add as a term.
         * @return void
         */
        public void addTerm(CriteriaTreeNode term) {
            terms.add(term);
        }

        /**
         * @description Get the id of this node's parent.
         * @return Id
         */
        public Id getParentId() {
            return parentId;
        }

        /**
         * @description Determine whether the given CampaignListMember meets
         * the criteria of *this node*.  If the node is a grouping node, i.e.
         * 'And' and 'Or' nodes, then this will evaluate the criteria
         * recursively for each term.
         *
         * @return Boolean (true if the CampaignListMember is eligible by the criteria of the criteria sub-tree represented by this node.
         */
        public abstract Boolean meetsCriteria(CampaignListMember m);
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This represents a logical grouping of other criteria nodes
     * such that all of the terms within this group must meet criteria the
     * criteria for inclusion for this node to meet the criteria for inclusion.
     */
    public class AndNode extends CriteriaTreeNode {
        /**
         * @description Construct an AndNode that references a parent node.
         * @param parentId The id of this node's parent node, or null if this node is the root node of the criteria tree.
         */
        public AndNode(Id parentId) {
            this.parentId = parentId;
        }

        /**
         * @description Determine whether the given CampaignListMember meets
         * the criteria of all of the terms within this AND grouping of
         * criteria nodes.
         *
         * @param m The CampaignListMember to determine whether eligible for inclusion in a campaign list
         * @return Boolean (true if the given CampaignListMember is eligible by the criteria of this node, false otherwise)
         */
        public override Boolean meetsCriteria(CampaignListMember m) {
            for (CriteriaTreeNode term : terms) {
                if (!term.meetsCriteria(m)) {
                    return false;
                }
            }
            return true;
        }
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This represents a logical grouping of other criteria nodes
     * such that at least one of the terms within this group must meet criteria
     * the criteria for inclusion for this node to meet the criteria for
     * inclusion.
     */
    public class OrNode extends CriteriaTreeNode {
        /**
         * @description Construct an OrNode that references a parent node.
         * @param parentId The id of this node's parent node, or null if this node is the root node of the criteria tree.
         */
        public OrNode(Id parentId) {
            this.parentId = parentId;
        }

        /**
         * @description Determine whether the given CampaignListMember meets the criteria of all of the terms within this OR grouping of criteria nodes.
         * @param m The CampaignListMember to determine whether eligible for inclusion in a campaign list
         * @return Boolean (true if the given CampaignListMember is eligible by the criteria of this node, false otherwise)
         */
        public override Boolean meetsCriteria(CampaignListMember m) {
            for (CriteriaTreeNode term : terms) {
                if (term.meetsCriteria(m)) {
                    return true;
                }
            }
            return false;
        }
    }

    /**
     * @author Salesforce.org
     * @group CampaignTools
     * @description This represents a source criteria node.  A
     * CampaignListMember is eligible for inclusion in a campaign list by this
     * node if the CampaignListMember was found in this node's source, or if
     * this is an exclusion source, then if the CampaignListMember was NOT
     * found in this node's source.
     */
    public class SourceNode extends CriteriaTreeNode {
        /**
         * @description The id of the source.  This could be something like the
         * Id of a Report, or the Id of a Campaign, or any other type of valid
         * source for CampaignListMembers
         */
        private Id sourceId;

        /**
         * @description True if this source node is meant to *exclude*
         * CampaignListMembers that are found in the specified source.  False,
         * otherwise.
         */
        private Boolean isExclusion;

        /**
         * @description Construct a SourceNode corresponding to a given source,
         * and whether or not eligibility is determined if a given
         * CampaignListMember is found in that source or if it is not found in
         * that source.
         *
         * @param parentId The id of the parent node that this source belongs to (such as an 'And' or 'Or' node) or null if this source is a root node, i.e. the only criteria in the criteria tree.
         * @param sourceId The id of the source (a Report, Campaign, etc.)
         * @param isExclusion True if this source node determines eligibility of a CampaignListMember is NOT included in the source.  False, otherwise.
         */
        public SourceNode(Id parentId, Id sourceId, Boolean isExclusion) {
            this.parentId = parentId;
            this.sourceId = sourceId;
            this.isExclusion = isExclusion;
        }

        /**
         * @description Get the id of this node's source.
         * @return Id
         */
        public Id getSourceId() {
            return sourceId;
        }

        /**
         * @description Is this source node intended to exclude the members
         * found in the source?
         *
         * @return Boolean
         */
        public Boolean isExclusion() {
            return isExclusion;
        }

        /**
         * @description Determine whether the given CampaignListMember is
         * eligible for inclusion in a campaign list based on whether the
         * CampaignListMember was found in this node's source.
         *
         * @param m The CampaignListMember to test for eligibility
         * @return Boolean (True if the CampaignListMember was found in this node's source and this is not an exclusion source, or if the CampaignListMember was *not* found in this node's source and this is an exclusion source. False, otherwise)
         */
        public override Boolean meetsCriteria(CampaignListMember m) {
            if (isExclusion) {
                return !m.isFromSource(sourceId);
            } else {
                return m.isFromSource(sourceId);
            }
        }
    }
}