@IsTest
private class InterventionControllerTest {
    private class FixedGeocoder implements ReverseGeocoder {
        public String toAddress(Decimal latitude, Decimal longitude) {
            return 'Akwa, Douala, Cameroon';
        }
    }

    private class FailingGeocoder implements ReverseGeocoder {
        public String toAddress(Decimal latitude, Decimal longitude) {
            throw new CalloutException('timeout');
        }
    }

    private class NominatimMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().startsWith(NominatimReverseGeocoder.ENDPOINT), 'Calls Nominatim');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"display_name":"Akwa, Douala, Cameroon"}');
            return res;
        }
    }

    private static ServiceAppointment newAppointment() {
        Account acc = new Account(Name = 'Test Customer');
        insert acc;
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = acc.Id,
            EarliestStartTime = System.now(),
            DueDate = System.now().addDays(1)
        );
        insert sa;
        return sa;
    }

    @IsTest
    static void startRecordsPositionAddressAndStartTime() {
        ServiceAppointment sa = newAppointment();
        InterventionController.geocoder = new FixedGeocoder();
        // Use a status that exists in every org's default picklist
        InterventionController.inProgressStatus = [SELECT Status FROM ServiceAppointment WHERE Id = :sa.Id].Status;

        Test.startTest();
        InterventionController.StartResult result = InterventionController.startIntervention(sa.Id, 4.0511, 9.7679);
        Test.stopTest();

        ServiceAppointment saved = [
            SELECT Start_Location__Latitude__s, Start_Location__Longitude__s, Start_Address__c, ActualStartTime
            FROM ServiceAppointment WHERE Id = :sa.Id
        ];
        System.assertEquals('Akwa, Douala, Cameroon', result.address);
        System.assertEquals('Akwa, Douala, Cameroon', saved.Start_Address__c);
        System.assertEquals(4.0511, saved.Start_Location__Latitude__s);
        System.assertNotEquals(null, saved.ActualStartTime);
    }

    @IsTest
    static void startsEvenWhenTheAddressCannotBeResolved() {
        ServiceAppointment sa = newAppointment();
        InterventionController.geocoder = new FailingGeocoder();
        InterventionController.inProgressStatus = [SELECT Status FROM ServiceAppointment WHERE Id = :sa.Id].Status;

        Test.startTest();
        InterventionController.StartResult result = InterventionController.startIntervention(sa.Id, 4.0511, 9.7679);
        Test.stopTest();

        System.assertEquals(null, result.address);
        System.assertNotEquals(null, [SELECT ActualStartTime FROM ServiceAppointment WHERE Id = :sa.Id].ActualStartTime);
    }

    @IsTest
    static void rejectsAnInvalidPosition() {
        ServiceAppointment sa = newAppointment();
        try {
            InterventionController.startIntervention(sa.Id, 120, 9.7);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void nominatimGeocoderReadsTheDisplayName() {
        Test.setMock(HttpCalloutMock.class, new NominatimMock());
        Test.startTest();
        String address = new NominatimReverseGeocoder().toAddress(4.0511, 9.7679);
        Test.stopTest();
        System.assertEquals('Akwa, Douala, Cameroon', address);
    }
}
