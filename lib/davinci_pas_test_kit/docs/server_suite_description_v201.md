The Da Vinci PAS Server Suite validates the conformance of server systems 
to the STU 2 version of the HL7® FHIR® 
[Da Vinci Prior Authorization Support Implementation Guide](https://hl7.org/fhir/us/davinci-pas/STU2/).

## Scope

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

These tests do not currently test the full scope of the IG. See the *Testing Limitations* section below 
for more details about the current scope of the tests and the reasons that some details have been left out.

## Running the Tests

### Quick Start

Execution of these tests require a significant amount of tester input in the
form of requests that Inferno will make against the server under test.

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

Requests will be made to the `/Claim/$submit` and `/Claim/$inquire` endpoints under the url provided in the "FHIR Server Endpoint URL" field.

### Authentication

The PAS IG states that 

> "PAS Servers **SHOULD** support server-server OAuth… In a future release of this guide, direction will limit the option to [require] server-server OAuth."

The PAS test kit currently assumes that the handshake has already occurred and requires
that a bearer token be provided in the “OAuth Credentials / Access Token” configuration
field. Inferno will submit this token on all requests it makes to the server as a part of 
executing the tests. A complete backend server authentication handshake may be supported
in future versions of the test kit.

### Payload

All other inputs are for providing bundles for Inferno to submit as a part of the tests. To avoid placing
requirements on the business logic, Inferno does not have standard requests to send as a part of the tests
and instead relies on the tester to provide the requests that Inferno will make.

For single-request fields (e.g., “PAS Submit Request Payload for Approval Response”), the input must be a json-encoded FHIR bundle.

For multiple-request fields (e.g., “Additional PAS Submit Request Payloads”), the input must be a json array of json-encoded FHIR bundles (e.g., [fhir-bundle-1, fhir-bundle-2, …] where each fhir-bundle-n is a full bundle).

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
    value sets will not be validated.
- Cannot verify the meaning of codes: validation that a given response conveys something specific, e.g., approval
    or pending, is not performed.
- Cannot verify matching semantics on inquiries: no checking of the identity of the ClaimResponse returned for an
    inquiry, e.g., that it matches the input or the original request.

These limitations may be removed in future versions of these tests. In the meantime, testers should consider these
requirements to be verified through attestation and should not represent their systems to have passed these tests
if these requirements are not met.

### Underspecified Subscription Details

The current PAS specification around subscriptions and notifications
is not detailed enough to support testing. Notably, 
- There are no examples of what a notification payload looks like
- There is no instruction on how to turn the notification payload into an inquiry

Once these details have been clarified, validation of the notification workflows
will be added to these tests.

### Future Details

The PAS IG places additional requirements on servers that are not currently tested by this test kit, including

- Prior Authorization update workflows
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
lable](https://github.com/inferno-framework/davinci-pas-test-kit/labels/source%20ig%20issue).