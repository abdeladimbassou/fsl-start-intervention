/**
 * Server side of the "Start Intervention" quick action on Service Appointment:
 * records where the technician starts, converts it into an address, and moves
 * the appointment to In Progress with its actual start time.
 */
public with sharing class InterventionController {
    @TestVisible
    private static ReverseGeocoder geocoder = new NominatimReverseGeocoder();

    @TestVisible
    private static String inProgressStatus = 'In Progress';

    public class StartResult {
        @AuraEnabled public String address;
        @AuraEnabled public String status;
    }

    @AuraEnabled
    public static StartResult startIntervention(Id appointmentId, Decimal latitude, Decimal longitude) {
        if (appointmentId == null || latitude == null || longitude == null) {
            throw new AuraHandledException('Appointment and position are required.');
        }
        if (Math.abs(latitude) > 90 || Math.abs(longitude) > 180) {
            throw new AuraHandledException('Invalid position.');
        }

        // Callout first: Salesforce does not allow a callout after uncommitted DML.
        String address;
        try {
            address = geocoder.toAddress(latitude, longitude);
        } catch (Exception e) {
            // The intervention starts even if the address cannot be resolved.
            address = null;
        }

        ServiceAppointment sa = [
            SELECT Id, Status, ActualStartTime
            FROM ServiceAppointment
            WHERE Id = :appointmentId
            WITH USER_MODE
            LIMIT 1
        ];
        sa.Start_Location__Latitude__s = latitude;
        sa.Start_Location__Longitude__s = longitude;
        sa.Start_Address__c = address;
        sa.Status = inProgressStatus;
        if (sa.ActualStartTime == null) {
            sa.ActualStartTime = System.now();
        }
        Database.update(sa, AccessLevel.USER_MODE);

        StartResult result = new StartResult();
        result.address = address;
        result.status = sa.Status;
        return result;
    }
}
