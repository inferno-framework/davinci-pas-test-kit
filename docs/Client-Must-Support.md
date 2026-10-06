# Client Must Support Tests

## Background

The must suppport flag is one mechanism used within FHIR to denote elements that
may not be required on all instances of a profile but are necessary to represent
the full scope of situations that the profile is designed to handle. Each FHIR IG
defines the precise meaning of must support within the profiles that it defines
and sets the requirements that the must support flag places on the different actors
defined by the IG.

Inferno generally validates must support definitions by analyzing a set of
resources gathered over one or more tests and checking that each must support
element defined in the relevant profile(s) has been observed populated at
lest once.

## PAS Must Support Definitions for Clients

PAS, in both the [v2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/background.html#must-support)
and [v2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformance.html#mustsupport)
versions that Inferno current has suites for, requires that clients follow the
[must support requirements defined in the Da Vinci HRex IG](https://hl7.org/fhir/us/davinci-hrex/1.2.0/en/conformance.html#mustsupport),
including when acting as a:
- **Data Source**: PAS clients act as a data source when they send information to
  the payer via the `$submit` and `$inquire` operations. HRex [requires data sources](https://hl7.org/fhir/us/davinci-hrex/1.2.0/en/conformance.html#ci-c-conf-1)
  to "be capable of populating the data element when sharing resources compliant
  with the profile." Taken together, this means that the PAS IG requires that PAS
  clients demonstrate the ability to populate all must support elements defined on
  PAS profiles that can appear within `$submit` and `$inquire` operation requests.
- **Data Consumer**: PAS clients act as a data consumer when they receive Bundles
  including a ClaimResponse and related details in `$submit` and `$inquire` operation
  responses or Subscription notifications. HRex [requires data consumers](https://hl7.org/fhir/us/davinci-hrex/1.2.0/en/conformance.html#ci-c-conf-1)
  to "be capable of processing resource instances containing the data elements
  without generating an error or causing the application to fail." Taken together,
  this means that the PAS IG requires that PAS clients demonstrate the ability to
  receive without erroring all must support elements defined on PAS profiles that
  can appear within `$submit` and `$inquire` operation responses (PAS Subscription
  notifications include the equivalent of a `$submit` response Bundle). A portion of
  this requirement is restated explicitly by the PAS IG for the Claim Response
  and Claim Inquiry Response profiles (in [v2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/background.html#must-support),
  [v2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformance.html#ci-c-conf-7)).

### Potential for future relaxed requirements

There are active discussions within the Da Vinci Burden Reduction community about
relaxing PAS must support requirements. Specifically, as of September 2026, there
is an [open ticket](https://jira.hl7.org/browse/FHIR-57903) that proposes to require
client systems to support only those elements which they collect and maintain within
their system. However, at this time, no final decision has been made and it is unclear
if the change would be applied to prior versions of the IG.

## Evaluated Messages

During testing, Inferno and the client system pass many requests and responses back
and forth. These are the messages that Inferno will consider when looking for
demonstration of must support elements. The "Must Support Elements" group allows
testers to make additional requests covering must support elements not yet demonstrated,
but elements previously demonstrated during previously executed scenario groups
do not need to be demonstrated again.

However, Inferno will only consider requests and responses exchanged during the most
recent execution of each group. When any group is re-run, including the "Must Support
Elements" group, the requests made during the previous run of that group will no longer
be considered.

Note that Inferno's mocked responses do not include all must support
elements, so testers will need to provide responses for Inferno to use that include
examples of all must support elements to pass these tests.

## Passing Inferno PAS Client Must Support Tests

To pass the client must support tests for the PAS Client suites defined in this repository,
Inferno requires that testers use the client system to
- Send `$submit` and `$inquire` requests that demonstrate the full scope of PAS profiles
  that can appear in those requests and their must support elements.
- Receive `$submit` and `$inquire` responses and notifications that demonstrate the full
  scope of PAS profiles that can appear in those responses and their must support elements.
  Additionally, confirm that the client system handled them without erroring as Inferno
  cannot directly observe how the client reacts. These attestations are performed immediately
  following each interaction.

The following sections detail what this means specifically in each supported PAS IG version.

### Da Vinci PAS v2.0.1

To pass the PAS client v2.0.1 must support tests, Inferno must see
- On Requests
  - All must support elements defined on the [PAS Claim](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim.html)
    or [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-update.html)
    profiles on `$submit` requests, or the [PAS Claim Inquiry](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-inquiry.html)
    profile on `$inquire` requests.
  - For `$submit` requests, at least one instance of one of the request resource profiles ([DeviceRequest](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-devicerequest.html),
    [MedicationRequest](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-medicationrequest.html),
    [NutritionOrder](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-nutritionorder.html),
    or [ServiceRequest](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-servicerequest.html))
    referenced from the [Requested Service extension](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-extension-requestedService.html)
    on element `Claim.item`, and all must support elements defined in the profiles for each
    request resource type that was observed.
  - For both `$submit` and `$inquire` requests, at least one instance of each other profile referenced from the PAS Claim profiles and
    all must support elements defined on those profiles. Specific
    profiles for which must support coverage must be demonstrated include:
    - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-coverage.html)
    - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-encounter.html)
    - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
    - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
    - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
    - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
    - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
    - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
- On Responses
  - All must support elements defined on the [PAS Claim Response](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claimresponse.html)
    or [PAS Claim Inquiry Response](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claiminquiryresponse.html)
    profiles for `$submit` and `$inquire` requests respectively.
  - For both `$submit` and `$inquire` requests, at least one instance of each
    other profile referenced from the PAS ClaimResponse profiles and all must support
    elements defined on those profiles. Specific profiles for which must support coverage
    must be demonstrated include:
    - [PAS CommunicationRequest](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-communicationrequest.html)
      (`$submit` responses only)
    - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
    - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
    - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
    - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
    - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
    - [PAS Task](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html)

### Da Vinci PAS v2.2.1

The PAS client v2.2.1 tests include some cases where the full must support requirements are not
checked, including
- Allows testers to indicate that they don't support must support elements on request profiles
  other than Claim profiles.
- Does not require demonstration of must support elements on response profiles other than
  ClaimResponse. These tests are optional and thus systems do not need to pass them to be conformant.

These relaxed requirements may be further loosened or re-tightened in the future.

To pass the PAS client v2.2.1 must support tests, Inferno must see
- On Requests
  - All must support elements defined on the [PAS Claim](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claim.html)
    or [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claim-update.html)
    profiles on `$submit` requests, or the [PAS Claim Inquiry](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claim-inquiry.html)
    profile on `$inquire` requests.
  - For `$submit` requests, at least one instance of one of the request resource profiles ([DeviceRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-devicerequest.html),
    [MedicationRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-medicationrequest.html),
    [NutritionOrder](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-nutritionorder.html),
    or [ServiceRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-servicerequest.html))
    referenced from the [Requested Service extension](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-extension-requestedService.html)
    on element `Claim.item`, and all must support elements defined in the profiles for each
    request resource type that was observed. Testers may attest that such elements not observed
    are not supported by their system and pass the test.
  - For both `$submit` and `$inquire` requests, at least one instance of each other profile referenced from the PAS Claim profiles and
    all must support elements defined on those profiles. Testers may attest that such
    elements not observed are not supported by their system and pass the test. Specific
    profiles for which must support coverage must be demonstrated include:
    - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-coverage.html)
    - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-encounter.html)
    - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-insurer.html)
    - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-requestor.html)
    - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-beneficiary.html)
    - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-subscriber.html)
    - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitioner.html)
    - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitionerrole.html)
- On Responses
  - All must support elements defined on the [PAS Claim Response](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claimresponse.html)
    or [PAS Claim Inquiry Response](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claiminquiryresponse.html)
    profiles for `$submit` and `$inquire` requests respectively.
  - Optionally, for both `$submit` and `$inquire` requests, at least one instance of each
    other profile referenced from the PAS ClaimResponse profiles and all must support
    elements defined on those profiles. Specific profiles for which must support coverage
    must be demonstrated include:
    - [PAS CommunicationRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-communicationrequest.html)
      (`$submit` responses only)
    - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-insurer.html)
    - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-requestor.html)
    - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-beneficiary.html)
    - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitioner.html)
    - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitionerrole.html)
    - [PAS Task](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-task.html)

