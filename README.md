# Field Service Toolkit for Salesforce

[![Apex tests](https://github.com/abdeladimbassou/fsl-start-intervention/actions/workflows/apex-tests.yml/badge.svg)](https://github.com/abdeladimbassou/fsl-start-intervention/actions/workflows/apex-tests.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

Three quick actions for **Service Appointments** that cover a technician's day on site, from arrival to sign-off. Built from real Field Service rollouts, rewritten from scratch with no client code.

| Action | What it does |
|---|---|
| **Start Intervention** | Records the technician's position (native location in the Field Service mobile app, browser geolocation elsewhere), converts it into an address, sets the appointment to In Progress with its actual start time. |
| **Order Part** | Requests a part from the field: creates a Product Request and its line item, linked to the appointment's work order. |
| **Complete Intervention** | Captures a work summary and the technician's and customer's signatures, generates a signed PDF service report attached to the appointment, sets it to Completed with its actual end time. |

The technician is never blocked: if the address cannot be resolved, the position is still saved.

## Install

Requires **Field Service** enabled in the org (and Field Service inventory for Order Part).

**One-click install** (unlocked package): *link added with the first package version.*

**From source:**

```bash
sf project deploy start --source-dir force-app --target-org my-org --test-level RunLocalTests
sf org assign permset --name Field_Service_Toolkit --target-org my-org
```

Then add the three actions to the Service Appointment page layout and to the Field Service mobile action list.

## What's inside

| Component | Role |
|---|---|
| `startIntervention`, `orderPart`, `completeIntervention` (LWC) | Screen quick actions |
| `signaturePad` (LWC) | Finger, pen or mouse signature, exported as PNG |
| `InterventionController`, `OrderPartController`, `CompleteInterventionController` (Apex) | Validation and updates in user mode |
| `ReverseGeocoder` + `NominatimReverseGeocoder` | Pluggable geocoding, OpenStreetMap by default |
| `ServiceReport` (Visualforce, PDF) + `ServiceReportController` | The signed service report |
| `Start_Location__c`, `Start_Address__c`, `Customer_Signed_By__c` | Fields on Service Appointment |
| `Field_Service_Toolkit` permission set | Apex, page and field access |
| Apex tests | One test class per controller |

## Design choices

- **Callout before DML** for geocoding: Salesforce forbids a callout after uncommitted DML.
- **User mode** for every query and write: the technician's sharing and field permissions apply.
- **Signatures and report as Files** on the appointment, so they sync to the mobile app and stay with the record.
- **Pluggable providers**: implement `ReverseGeocoder` for Google, Mapbox or an internal service. Nominatim's usage policy allows only low volumes.

## Continuous integration

`.github/workflows/apex-tests.yml` creates a scratch org with Field Service, deploys the toolkit and runs the Apex tests on every push and pull request. It needs one repository secret, `DEVHUB_SFDX_AUTH_URL` (see `sf org display --verbose` on your Dev Hub).

## License

MIT. Built by [Abdeladim Bassou](https://my-portfolio-seven-liard-59.vercel.app), Salesforce developer specialised in Field Service and OmniStudio.
