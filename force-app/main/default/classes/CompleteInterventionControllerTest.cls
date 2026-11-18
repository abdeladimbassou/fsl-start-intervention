@IsTest
private class CompleteInterventionControllerTest {
    private static final String PNG = 'data:image/png;base64,' + EncodingUtil.base64Encode(Blob.valueOf('signature'));

    private static ServiceAppointment newAppointment() {
        Account acc = new Account(Name = 'Test Customer');
        insert acc;
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = acc.Id, EarliestStartTime = System.now(), DueDate = System.now().addDays(1));
        insert sa;
        // Keep the org's own status values valid in the test
        CompleteInterventionController.completedStatus = [SELECT Status FROM ServiceAppointment WHERE Id = :sa.Id].Status;
        return sa;
    }

    @IsTest
    static void completeSavesSignaturesReportAndEndTime() {
        System.runAs(ToolkitTestSupport.toolkitUser()) {
            ServiceAppointment sa = newAppointment();
            Test.startTest();
            CompleteInterventionController.CompleteResult result =
                CompleteInterventionController.completeIntervention(sa.Id, 'Replaced the fuser unit', 'Jane Customer', PNG, PNG);
            Test.stopTest();

            ServiceAppointment saved = [SELECT ActualEndTime, Customer_Signed_By__c, Description FROM ServiceAppointment WHERE Id = :sa.Id];
            System.assertNotEquals(null, saved.ActualEndTime);
            System.assertEquals('Jane Customer', saved.Customer_Signed_By__c);
            System.assertEquals('Replaced the fuser unit', saved.Description);
            System.assertNotEquals(null, result.reportId);
            System.assertEquals(3, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :sa.Id], 'Two signatures and one report');
        }
    }

    @IsTest
    static void missingSignatureIsRejected() {
        System.runAs(ToolkitTestSupport.toolkitUser()) {
            ServiceAppointment sa = newAppointment();
            try {
                CompleteInterventionController.completeIntervention(sa.Id, null, 'Jane Customer', PNG, '');
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assertEquals(0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :sa.Id], 'Nothing saved');
            }
        }
    }

    @IsTest
    static void reportControllerLoadsTheAppointment() {
        System.runAs(ToolkitTestSupport.toolkitUser()) {
            ServiceAppointment sa = newAppointment();
            PageReference page = Page.ServiceReport;
            page.getParameters().put('id', sa.Id);
            page.getParameters().put('tech', 'not-an-id');
            Test.setCurrentPage(page);
            ServiceReportController ctrl = new ServiceReportController();
            System.assertEquals(sa.Id, ctrl.appointment.Id);
            System.assertEquals(null, ctrl.technicianSignatureUrl, 'Invalid ids are ignored');
        }
    }
}
