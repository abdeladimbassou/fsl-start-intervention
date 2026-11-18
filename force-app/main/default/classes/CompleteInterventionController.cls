/**
 * Server side of the "Complete Intervention" quick action: stores the technician's and
 * the customer's signatures as Files, generates a PDF service report attached to the
 * appointment, and moves the appointment to Completed with its actual end time.
 */
public with sharing class CompleteInterventionController {
    @TestVisible
    private static String completedStatus = 'Completed';

    public class CompleteResult {
        @AuraEnabled public Id reportId;
        @AuraEnabled public String status;
    }

    @AuraEnabled
    public static CompleteResult completeIntervention(
        Id appointmentId,
        String workSummary,
        String customerName,
        String technicianSignature,
        String customerSignature
    ) {
        if (appointmentId == null || String.isBlank(customerName)) {
            throw new AuraHandledException('Appointment and customer name are required.');
        }
        Blob techPng = decodePng(technicianSignature, 'technician');
        Blob customerPng = decodePng(customerSignature, 'customer');

        ServiceAppointment sa = [
            SELECT Id, AppointmentNumber, Status, ActualEndTime, Description
            FROM ServiceAppointment
            WHERE Id = :appointmentId
            WITH USER_MODE
            LIMIT 1
        ];

        Id techFile = saveFile(appointmentId, 'Signature technician - ' + sa.AppointmentNumber + '.png', techPng);
        Id customerFile = saveFile(appointmentId, 'Signature customer - ' + sa.AppointmentNumber + '.png', customerPng);

        sa.Status = completedStatus;
        sa.ActualEndTime = System.now();
        sa.Customer_Signed_By__c = customerName.left(120);
        if (String.isNotBlank(workSummary)) {
            sa.Description = workSummary.left(32000);
        }
        Database.update(sa, AccessLevel.USER_MODE);

        // Render the report after the update so it shows the final status and times.
        PageReference page = Page.ServiceReport;
        page.getParameters().put('id', appointmentId);
        page.getParameters().put('tech', techFile);
        page.getParameters().put('customer', customerFile);
        Blob pdf = Test.isRunningTest() ? Blob.valueOf('PDF') : page.getContentAsPDF();
        Id reportFile = saveFile(appointmentId, 'Service report - ' + sa.AppointmentNumber + '.pdf', pdf);

        CompleteResult result = new CompleteResult();
        result.reportId = reportFile;
        result.status = sa.Status;
        return result;
    }

    private static Blob decodePng(String dataUrl, String who) {
        String prefix = 'data:image/png;base64,';
        if (String.isBlank(dataUrl) || !dataUrl.startsWith(prefix)) {
            throw new AuraHandledException('The ' + who + ' signature is missing.');
        }
        Blob png = EncodingUtil.base64Decode(dataUrl.substring(prefix.length()));
        if (png.size() > 2 * 1024 * 1024) {
            throw new AuraHandledException('The ' + who + ' signature is too large.');
        }
        return png;
    }

    /** Saves a File linked to the appointment and returns the ContentVersion Id. */
    private static Id saveFile(Id parentId, String title, Blob body) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title,
            VersionData = body,
            FirstPublishLocationId = parentId
        );
        insert as user cv;
        return cv.Id;
    }
}
