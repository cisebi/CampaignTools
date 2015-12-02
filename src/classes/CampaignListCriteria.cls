public class CampaignListCriteria {
    private CriteriaTreeNode rootNode;

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

    public Boolean meetsCriteria(CampaignListMember m) {
        return rootNode.meetsCriteria(m);
    }

    public abstract class CriteriaTreeNode {
        private Id parentId;
        private List<CriteriaTreeNode> terms = new List<CriteriaTreeNode>();

        public void addTerm(CriteriaTreeNode term) {
            terms.add(term);
        }

        public Id getParentId() {
            return parentId;
        }

        public abstract Boolean meetsCriteria(CampaignListMember m);
    }

    public class AndNode extends CriteriaTreeNode {
        public AndNode(Id parentId) {
            this.parentId = parentId;
        }

        public override Boolean meetsCriteria(CampaignListMember m) {
            for (CriteriaTreeNode term : terms) {
                if (!term.meetsCriteria(m)) {
                    return false;
                }
            }
            return true;
        }
    }

    public class OrNode extends CriteriaTreeNode {
        public OrNode(Id parentId) {
            this.parentId = parentId;
        }

        public override Boolean meetsCriteria(CampaignListMember m) {
            for (CriteriaTreeNode term : terms) {
                if (term.meetsCriteria(m)) {
                    return true;
                }
            }
            return false;
        }
    }

    public class SourceNode extends CriteriaTreeNode {
        private Id sourceId;
        private Boolean isExclusion;

        public SourceNode(Id parentId, Id sourceId, Boolean isExclusion) {
            this.parentId = parentId;
            this.sourceId = sourceId;
            this.isExclusion = isExclusion;
        }

        public override Boolean meetsCriteria(CampaignListMember m) {
            if (isExclusion) {
                return !m.isFromSource(sourceId);
            } else {
                return m.isFromSource(sourceId);
            }
        }
    }
}