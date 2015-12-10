@isTest
public class ReportService_TEST {
    @isTest(SeeAllData=True)
    public static void testReportIterator() {

        List<Contact> testContacts = new List<Contact>();

        for (Integer i = 0; i < 2500; i++) {
            testContacts.add(new Contact(
                LastName = 'Test Contact',
                Description = 'NPSP Test Contact'
            ));
        }

        insert testContacts;

        Set<Id> expectedIds = (new Map<Id, Contact>(testContacts)).keySet();

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'NPSP_Test_Contact_Report'
        ];

        String columnName = 'CONTACT_ID';

        Test.startTest();

        Iterable<Object> reportRowValueIterable = new ReportService.ReportRowValueIterableIterator(
            testReport.Id,
            'CONTACT_ID'
        );

        Iterator<Object> reportRowValueIterator = reportRowValueIterable.iterator();

        Set<Id> actualIds = new Set<Id>();

        while(reportRowValueIterator.hasNext()) {
            actualIds.add((Id) reportRowValueIterator.next());
        }

        Test.stopTest();

        System.assertEquals(expectedIds, actualIds);
    }
}