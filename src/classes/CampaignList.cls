public abstract class CampaignList {

    public interface Service {
        void updateCampaignFromCampaignList(Id campaignId, Id rootSegmentId);
        void updateCampaignStatus(Id campaignId, UpdateStatus status);
    }

    public interface Member {
        Id getId();
        Id getRelatedId();
        void addSource(Id sourceId, String sourceName);
        Boolean isFromSource(Id sourceId);
        Boolean meetsCriteria(Segment segment);
        Member__c getSObject();
        CampaignMember getCampaignMember();
    }

    public interface MemberMapper {
        void updateByRelatedIdsAndSource(List<Id> relatedIds, Id rootSegmentId, Id sourceId, String sourceName);
        void addMembersToCampaign(List<Member> members, Id campaignId);
    }

    public interface Segment extends Iterable<Segment>{
        Id getId();
        Id getParentId();
        Id getRootSegmentId();
        void addChild(CampaignList.Segment child);
        List<Segment> getChildren();
        Boolean meetsCriteria(Member member);
    }

    public interface SegmentMapper {
        String getSourceNameById(Id sourceId);
        Segment getSegmentTreeByRootId(Id rootSegmentId);
    }

    public abstract class CustomException extends System.Exception {}
    public abstract class SegmentMapperException extends CustomException {}
    public class InvalidSegmentSObjectException extends SegmentMapperException {}

    /**
     * @description This enum has values that correspond the state of a
     * Campaign as it is being updated from a campaign list.  RUNNING means
     * that the Campaign is currently being updated.  SUCCESS means that the
     * last time the Campaign was updated from a campaign list, there were no
     * issues.  FAILURE means that the last time the Campaign was attempted to
     * be updated from a campaign list, there was an error that prevented
     * successful update.
     */
    public enum UpdateStatus {
        RUNNING,
        SUCCESS,
        FAILURE
    }

    private static Service service_x = new CampaignListService();
    private static MemberMapper memberMapper_x = new CampaignListMemberMapper();
    private static SegmentMapper segmentMapper_x = new CampaignListSegmentMapper();

    public static void setService(Service s) {
        service_x = s;
    }

    public static Service getService() {
        return service_x;
    }

    public static void setMemberMapper(MemberMapper mm) {
        memberMapper_x = mm;
    }

    public static MemberMapper getMemberMapper() {
        return memberMapper_x;
    }

    public static void setSegmentMapper(SegmentMapper sm) {
        segmentMapper_x = sm;
    }

    public static SegmentMapper getSegmentMapper() {
        return segmentMapper_x;
    }
}