/**
 * Default ReverseGeocoder backed by OpenStreetMap Nominatim.
 * Nominatim's usage policy asks for low volume and an identifying User-Agent:
 * for production volumes, use a commercial provider through your own ReverseGeocoder.
 */
public with sharing class NominatimReverseGeocoder implements ReverseGeocoder {
    @TestVisible
    private static final String ENDPOINT = 'https://nominatim.openstreetmap.org/reverse';

    public String toAddress(Decimal latitude, Decimal longitude) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + '?format=jsonv2&zoom=18&lat=' + latitude + '&lon=' + longitude);
        req.setMethod('GET');
        req.setHeader('User-Agent', 'fsl-start-intervention (Salesforce)');
        req.setHeader('Accept-Language', UserInfo.getLanguage().replace('_', '-'));
        req.setTimeout(10000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            return null;
        }
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Object name = body.get('display_name');
        return name == null ? null : String.valueOf(name).left(255);
    }
}
