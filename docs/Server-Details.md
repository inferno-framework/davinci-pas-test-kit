# Server Suite Implementation Details

The Da Vinci PAS Server Suite validates the conformance of server systems 
to versions [2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/) and
[2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/) of the HL7® FHIR® Da Vinci Prior Authorization Support Implementation Guide.
This documentation covers both versions of the server suite.

These tests are a **DRAFT** intended to allow PAS server implementers to perform 
preliminary checks of their servers against PAS IG requirements and [provide 
feedback](https://github.com/inferno-framework/davinci-pas-test-kit/issues) 
on the tests. Future versions of these tests may validate other 
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a client and make a series of prior authorization requests to the 
server under test. Over the course of these requests, Inferno will seek to observe
conformant handling of PAS requirements, including
- The ability of the server to use PAS API interactions to communicate 
    - Approval of a prior authorization request
    - Denial of a prior authorization request
    - Pending of a prior authorization request and a subsequent final decision
    - Claim Updates (v2.2.1 only)
    - Inability to process a prior authorization request
- The ability of the server to handle the full scope of data required by PAS, including
    - Ability to process prior auth requests and inquiries with all PAS profiles and all must support elements on those profiles
    - Ability to return responses that demonstrate the use of all PAS profiles and all must support elements on those profiles

Because the business logic that determines decisions and the elements populated in responses
Is outside of the PAS specification and will vary between implementers, testers
are required to provide the requests that Inferno will make to the server.

All requests and responses will be checked for conformance to the PAS
IG requirements individually and used in aggregate to determine whether
required features and functionality are present. HL7® FHIR® resources are 
validated with the Java validator using `tx.fhir.org` as the terminology server.

The v2.2.1 suite validates resources against the PAS 2.2.1 and US Core 6.1.0 implementation guides.

These tests do not currently test the full scope of the IG. See the *Testing Limitations* section below 
for more details about the current scope of the tests and the reasons that some details have been left out.

## Running the Tests

### Quick Start

Execution of these tests require a significant amount of tester input in the
form of requests that Inferno will make against the server under test.

For v2.2.1, see the [v2.2.1 server instructions](Server-Instructions-v2.2.1) for version-specific
setup and execution steps. The public reference server example below applies to v2.0.1.

If you would like to try out the tests using examples from the IG against the
[public reference server endpoint](https://prior-auth.davinci.hl7.org/fhir) ([code on github](https://github.com/HL7-DaVinci/prior-auth)), you can do so by 
1. Selecting the *Prior Authorization Support Reference Implementation* option from the Preset dropdown in the upper left
2. Clicking the *Run All Tests* button in the upper right
3. Clicking the *Submit* button at the bottom of the input dialog

You can run these tests using your own server by updating the "FHIR Server Endpoint URL" and "OAuth Credentials" inputs.

Note that:
- the inputs for these tests are not complete and systems are not expected to pass the tests based on them.
- the public reference server has not been updated to reflect the STU2 version that these tests target,
    so expect some additional failures when testing against it.

## Test Configuration Details

The details provided here supplement the documentation of individual fields in the input dialog
that appears when initiating a test run.

### Server identification

Requests will be made to the `/Claim/$submit`, `/Claim/$inquire`, and `/Subscription` endpoints under the url provided in the "FHIR Server Endpoint URL" field.

### Authentication

The PAS IG states that 

> "PAS Servers **SHOULD** support server-server OAuth… In a future release of this guide, direction will limit the option to [require] server-server OAuth."

The **OAuth Credentials** input is optional for test environments that do not require authentication.
When authentication is required, it must authorize Inferno to invoke the PAS operations and create the
Subscription. The v2.2.1 suite accepts an access-token or backend-service configuration and uses it to
apply credentials to its outbound requests. The server suite does not separately evaluate an
OAuth interaction as a server-test result.

### Payload

All other inputs are for providing bundles for Inferno to submit as a part of the tests. To avoid placing
requirements on the business logic, Inferno does not have standard requests to send as a part of the tests
and instead relies on the tester to provide the requests that Inferno will make.

For single-request fields (e.g., “PAS Submit Request Payload for Approval Response”), the input must be a json-encoded FHIR bundle.

For multiple-request fields (e.g., “Additional PAS Submit Request Payloads”), the input must be a json array of json-encoded FHIR bundles (e.g., [fhir-bundle-1, fhir-bundle-2, …] where each fhir-bundle-n is a full bundle).

### Claim Updates (v2.2.1)

The v2.2.1 **Claim Updates** group sends four tester-provided `$submit` requests in order: an initial Claim
submission, an update that adds an item, an update that modifies one item and cancels another, and an update that
cancels the entire request. The Bundles must form a stateful sequence for the server under test.

Inferno validates each response against the corresponding request: each response must echo submitted item sequences
and include current results for all submitted items. It does not compare item sequences between different update steps.

### Error handling (v2.2.1)

The **Demonstrate Error Handling** group requires no tester-provided error payload. Inferno submits an intentionally
nonconformant, empty Bundle to both `$submit` and `$inquire`. The server is expected to return a non-2xx response
containing an `OperationOutcome`.

### Subscription

To provide updates on prior authorization requests that have been pended because a final answer will take longer than
the allowed response window, servers need to support FHIR Subscriptions. Subscriptions are made at the level of the
Organization submitting the prior authorization requests and so is expected to be performed once when a provider
system registers with a specific payer.

Inferno supports that workflow by splitting out Subscription setup tests into a group that can be run before the
pended workflow group. Inferno assumes that the Subscriptions API is located under the same FHIR base URL as
the `Claim/$submit` operation and that it uses the same authentication. Testers will provide the following inputs:
- **Pended Prior Authorization Subscription**: A Subscription body for Inferno to submit to the server under test. 
  When submitted to the server under test, it should cause notifications to be generated when pended prior
  authorization requests submitted by Inferno are updated. Inferno will modify it to ensure that it points to
  the correct Inferno notification endpoint.
- **Notification Access Token**: An access token that the server under test will send to Inferno on notifications
  so that the request gets associated with this test session. The token must be provided as a Bearer token in the
  Authorization header of HTTP requests sent to Inferno.

During the pended workflow test, testers will demonstrate that an update to the submitted and pended prior authorization
request causes the Subscription to trigger and send a notification to Inferno.

The v2.0.1 and v2.2.1 pended workflows differ in that Inferno expects `id-only` notification content in v2.0.1 and
`full-resource` notification content in v2.2.1.

## Testing Limitations

### Private X12 details

HIPAA [requires](https://hl7.org/fhir/us/davinci-pas/STU2/regulations.html) electronic prior authorization
processing to use the X12 278 standard. While recent CMS rule-making suggests that [this requirement
will not be enforced in the future](https://www.cms.gov/newsroom/fact-sheets/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f),
the current PAS IG relies heavily on X12.  As the IG authors note at the
top of the [IG home page](https://hl7.org/fhir/us/davinci-pas/STU2/):

> Note that this implementation guide is intended to support mapping between FHIR and X12 transactions. To respect
> X12 intellectual property, all mapping and X12-specific terminology information will be solely published by X12
> and made available in accordance with X12 rules - which may require membership and/or payment. Please see this
> [Da Vinci External Reference page](https://confluence.hl7.org/display/DVP/Da+Vinci+Reference+to+External+Standards+and+Terminologies) 
> for details on how to get this mapping.
>
> There are many situationally required fields that are specified in the X12 TRN03 guide that do not have guidance
> in this Implementation Guide. Implementers need to consult the X12 PAS guides to know the requirements for these
> fields.
>
> Several of the profiles will require use of terminologies that are part of X12 which we anticipate being made
> publicly available. At such time as this occurs, the implementation guide will be updated to bind to these as
> external terminologies.

The implications of this reliance on proprietary information that is not publicly available means that this test
kit:

- Cannot verify the correct usage of X12-based terminology: terminology requirements for all elements bound to X12
    value sets will not be validated beyond the expected codes indicating approval, denial, and pended decisions.
- Cannot verify matching semantics on inquiries: no checking of the identity of the ClaimResponse returned for an
    inquiry, e.g., that it matches the input or the original request.

These limitations may be removed in future versions of these tests. In the meantime, testers should consider these
requirements to be verified through attestation and should not represent their systems to have passed these tests
if these requirements are not met.

### Future Details

The PAS IG places additional requirements on servers that are not currently tested by this test kit, including

- Prior Authorization update workflows (v2.0.1)
- Requests for additional information handled through the CDex framework
- PDF, CDA, and JPG attachments
- US Core profile support for supporting information
- Inquiry matching and subsetting logic
- Inquiry requests from non-submitting systems
- Collection of metrics

These and any other requirements found in the PAS IG may be tested in future versions of these tests.

### Known Issues

Testing has identified issues with the source IG that result in spurious failures. 
Tests impacted by these issues have an indication in their documentations. The full
list of known issues can be found on the [repository's issues page with the 'source ig issue'
label](https://github.com/inferno-framework/davinci-pas-test-kit/labels/source%20ig%20issue).
