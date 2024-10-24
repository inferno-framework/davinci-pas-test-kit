The Da Vinci PAS Test Kit Client Suite validates the conformance of client
systems to the STU 2 version of the HL7® FHIR®
[Da Vinci Prior Authorization Support Implementation Guide](https://hl7.org/fhir/us/davinci-pas/STU2/).

## Scope

These tests are a **DRAFT** intended to allow PAS client implementers to perform
preliminary checks of their clients against PAS IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-pas-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a PAS server for the client under test to interact with. The client
will be expected to initiate requests to the server and demonstrate its ability to react
to the returned responses. Over the course of these interactions,
Inferno will seek to observe conformant handling of PAS requirements, including
- The ability of the client to initiate and react to
    - The approval of a prior authorization request
    - The denial of a prior authorization request
    - The pending of a prior authorization request and a subsequent final decision
- The ability of the client to provide data covering the full scope of required by PAS, including
    - The ability to send prior auth requests and inquiries with all PAS profiles and all must support elements on
    those profiles
    - The ability to handle responses that contain all PAS profiles and all must support elements on those
    profiles (not included in the current version of these tests)

Because X12 details, including coded values indicating details like “denied” and “pended”,
are not public, Inferno is not currently able to generate a full set of responses to requests
or otherwise provide details on specific codes used to represent those concepts
and is limited to responses that look similar to the examples in the IG (e.g., [here](https://hl7.org/fhir/us/davinci-pas/STU2/Bundle-ReferralAuthorizationResponseBundleExample.html)).
Thus,

- In order to demonstrate specific workflows, namely pend and denial, users will need to provide the expected
response for Inferno to send back
- The current tests do not return to the client all PAS profiles and must support elements to confirm support.

For further details on limitations of these tests, see the *Testing Limitations* section below.

All requests and responses will be checked for conformance to the PAS
IG requirements individually and used in aggregate to determine whether
required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

For Inferno to simulate a server that always returns approved responses, it needs
only to know the bearer token that the client will send on requests, for which there are two options.

1. If you want to choose your own bearer token, then
    1. Select the "2. PAS Client Validation" test from the list on the left.
    2. Click the '*Run All Tests*' button on the right.
    3. In the "access_token" field, enter the bearer token that will be sent by the client under test (as part
        of the Authorization header - Bearer: <provided value>).
    4. Click the '*Submit*' button at the bottom of the dialog.
2. If you want to use a client_id to obtain an access token, then
    1. Click the '*Run All Tests*' button on the right.
    2. Provide the client's registered id "client_id" field of the input (NOTE, Inferno doesn't support the
        registration API, so this must be obtained from another system or configured manually).
    3. Click the '*Submit*' button at the bottom of the dialog.
    4. Make a token request that includes the specified client id to the
        `<inferno host>/custom/davinci_pas_client_suite_v201/mock_auth/token` endpoint to get
        an access token to use on the request of the requests.

In either case, the tests will continue from that point, requesting the user to
direct the client to make certain requests to demonstrate PAS client capabilities.

Note: authentication options for these tests have not been finalized and are subject to change.

### Complete Setup

The *Quick Start* approach does not test pended or deny workflows. To test these, provide a
json-encoded FHIR bundle in the "Claim pended response JSON" and "Claim deny response JSON" input field after
clicking the '*Run All Tests*' button. These responses will be echoed back when a request
is made during the corresponding test.

Selecting the *Example PAS Server Responses* Preset in the dropdown in the upper left will fill in example
FHIR bundles for the pended and deny responses. It will also fill in a sample value for the Client ID,
which is only necessary for the *Demonstrate Authorization* test group, which can be skipped in favor of
manual bearer token input in subsequent tests as described above.

### Postman-based Demo

If you do not have a PAS client but would like to try the tests out, you can use
[this postman collection](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/config/PAS%20Test%20Kit%20Client%20Test%20Demo.postman_collection.json)
to make requests against Inferno. The following requests and example responses from that collection can be used.

- Configuration
- *Deny Response* example under the *Homecare Prior Authorization Request*: use as the value of the
    "Claim denied response JSON" input field. NOTE: this contains a placeholder code `DENIEDCODE` for the
    X12 code representing the denied status. Replace with the X12-specified code before providing to Inferno
    to accurately replicate a denial workflow for the client under test.
- *Pend Response* example under the *Medical Services Prior Authorization Request*: use as the value of the
    "Claim pended response JSON" input field. NOTE: this contains a placeholder code `PENDEDCODE` for the
    X12 code representing the pended status. Replace with the X12-specified code before providing to Inferno
    to accurately replicate a pend workflow for the client under test.
- Submissions
- *mock token*: for submitting a client id to get back an access token to use on the rest of the tests. Set the
    collection's access_token variable to the result.
- *Referral Prior Authorization Request*: use for the "Approval" workflow test submission.
- *Medical Services Prior Authorization Request*: use for the "Pended" workflow test submission.
- *Medical Services Inquiry Request*: use for the "Pended" workflow test inquiry.

No additional requests are present to submit as a part of the must support tests, so
testers can simply click the link to indicate they are done submitting requests. Note
that the requests within the Postman client are not expected to fully pass the tests as they
do not contain all must support items.

## Testing Limitations

### Private X12 details

HIPAA [requires](https://hl7.org/fhir/us/davinci-pas/STU2/regulations.html) electronic prior authorization
processing to use the X12 278 standard. While recent CMS rule-making suggests that [this requirement
will not be enforced in the future](https://www.cms.gov/newsroom/fact-sheets/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f),
the current PAS IG relies heavily on X12.  As the IG authors note at the
top of the [IG home page](https://hl7.org/fhir/us/davinci-pas/STU2/index.html):

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

The PAS IG places additional requirements on clients that are not currently tested by this test kit, including

- Prior Authorization update workflows
- Requests for additional information handled through the CDex framework
- PDF, CDA, and JPG attachments
- US Core profile support for supporting information
- The ability to handle responses containing all PAS-defined profiles and must support elements
- Most details requiring manual review of the client system, e.g., the requirement that clinicians can update
details of the prior authorization request before submitting them

These and any other requirements found in the PAS IG may be tested in future versions of these tests.

### Known Issues

Testing has identified issues with the source IG that result in spurious failures. 
Tests impacted by these issues have an indication in their documentations. The full
list of known issues can be found on the [repository's issues page with the 'source ig issue'
label](https://github.com/inferno-framework/davinci-pas-test-kit/labels/source%20ig%20issue).