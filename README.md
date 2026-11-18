# Start Intervention for Salesforce Field Service

A quick action for **Service Appointments** that a technician taps when arriving on site. It:

1. records the technician's position (native location in the Field Service mobile app, browser geolocation elsewhere);
2. converts it into a readable address (reverse geocoding, pluggable provider);
3. moves the appointment to **In Progress** and sets its **Actual Start Time**.

The intervention still starts if the address cannot be resolved: the position is always saved.

## What's inside

| Component | Role |
|---|---|
| `startIntervention` (LWC, screen quick action) | Gets the position and calls Apex |
| `InterventionController` (Apex) | Validates input, geocodes, updates the appointment in user mode |
| `ReverseGeocoder` (interface) | Plug in Google, Mapbox or an internal service |
| `NominatimReverseGeocoder` | Default provider: OpenStreetMap Nominatim |
| `Start_Location__c`, `Start_Address__c` | New fields on Service Appointment |
| `Start_Intervention` permission set | Apex and field access |
| `InterventionControllerTest` | Tests for success, geocoding failure, invalid input and the Nominatim parser |

## Install

Requires **Field Service** enabled in the org.

```bash
sf project deploy start --source-dir force-app --target-org my-org --test-level RunSpecifiedTests --tests InterventionControllerTest
sf org assign permset --name Start_Intervention --target-org my-org
```

Then add the **Start Intervention** action to the Service Appointment page layout (and to the mobile action list for the Field Service app).

## Using another geocoding provider

Nominatim's usage policy allows only low volumes. For production, implement `ReverseGeocoder` and set it in `InterventionController.geocoder`, with the provider's host in a Remote Site Setting or a Named Credential.

## Design choices

- **Callout before DML**: Salesforce forbids a callout after uncommitted DML, so the address is resolved first.
- **User mode** for the query and the update: the technician's sharing and field permissions apply.
- **Never block the technician**: a geocoding failure leaves the address empty but still starts the intervention.

## License

MIT. Built by [Abdeladim Bassou](https://my-portfolio-seven-liard-59.vercel.app), Salesforce developer specialised in Field Service and OmniStudio.
