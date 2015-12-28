@isTest
private class ReportService_TEST {
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

        Iterable<Id> reportRowIdIterable = new ReportService.ReportRowIdIterableIterator(
            testReport.Id,
            'CONTACT_ID'
        );

        Iterator<Id> reportRowIdIterator = reportRowIdIterable.iterator();

        Set<Id> actualIds = new Set<Id>();

        while(reportRowIdIterator.hasNext()) {
            actualIds.add(reportRowIdIterator.next());
        }

        Test.stopTest();

        System.assertEquals(expectedIds, actualIds);
    }
}