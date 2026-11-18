/** Data for the ServiceReport Visualforce page rendered as PDF. */
public with sharing class ServiceReportController {
    public ServiceAppointment appointment { get; private set; }
    public String technicianSignatureUrl { get; private set; }
    public String customerSignatureUrl { get; private set; }
    public String technicianName { get; private set; }

    private static final Pattern VERSION_ID = Pattern.compile('^068[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?$');

    public ServiceReportController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        Id appointmentId = params.get('id');
        appointment = [
            SELECT Id, AppointmentNumber, Subject, Status, Street, City, Country,
                   ActualStartTime, ActualEndTime, Description, Customer_Signed_By__c,
                   Start_Address__c, Account.Name
            FROM ServiceAppointment
            WHERE Id = :appointmentId
            WITH USER_MODE
            LIMIT 1
        ];
        technicianName = UserInfo.getName();
        technicianSignatureUrl = signatureUrl(params.get('tech'));
        customerSignatureUrl = signatureUrl(params.get('customer'));
    }

    private static String signatureUrl(String versionId) {
        if (String.isBlank(versionId) || !VERSION_ID.matcher(versionId).matches()) {
            return null;
        }
        return '/sfc/servlet.shepherd/version/download/' + versionId;
    }
}
