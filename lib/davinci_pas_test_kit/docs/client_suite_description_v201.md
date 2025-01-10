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
- The ability of the client to initiate a prior authorization submission and react to
    - The approval of the request
    - The denial of the request
    - The pending of the request and a subsequent notification that a final decision was made
- The ability of the client to provide data covering the full scope of required by PAS, including
    - The ability to send prior auth requests and inquiries with all PAS profiles and all must support elements on
    those profiles
    - The ability to handle responses that contain all PAS profiles and all must support elements on those
    profiles (not included in the current version of these tests)

Inferno contains basic logic to generate approval, denial, and pended responses, along with a
notification that a final decision was made, as a part of the above workflows.
These responses are based on examples available in the PAS Implementation Guide
and are conformant, but may not meet the needs of actual implementations. Thus,
testers may provide Inferno with specific responses for Inferno to echo. If responses
are provided, Inferno will check them for conformance to ensure that they demonstrate
a fully conformant exchange.

All requests and responses will be checked for conformance to the PAS
IG requirements individually and used in aggregate to determine whether
required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

For Inferno to simulate a server that returns basic mocked responses, it needs
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

In either case, the tests will continue from that point, requesting the tester to
direct the client to make certain requests to demonstrate PAS client capabilities.

Note: authentication options for these tests have not been finalized and are subject to change.

### Postman-based Demo

If you do not have a PAS client but would like to try the tests out, you can use
[this postman collection](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/config/PAS%20Test%20Kit%20Client%20Test%20Demo.postman_collection.json)
to make requests against Inferno and see the mocked responses provided by Inferno. To use, load
the collection into the [Postman app](https://www.postman.com/downloads/) and follow these steps:

1. Select the *PAS Client Test Suite Demo* Collection in postman and go to the "Variables" tab 
   (see the Overview tab for more details on what the variables control).
1. Note the "Current value" of the **client_id** variable for use in configuring Inferno. Update it
   to another value to use instead, if desired.
1. Start a Da Vinci PAS Client Suite v2.0.1 session from the [PAS Test Kit page on 
   inferno.healthit.gov](https://inferno.healthit.gov/test-kits/davinci-pas/). 
1. Click the *Run All Tests* button in the upper right hand corner of the suite.
1. In the **Client ID** input, enter the value from the **client_id** Postman variable and click the 
   *Submit* button.
1. When the "User Action" dialog appears, return to Postman and change to the Authorization tab. Scroll down 
   to find the *Get New Access Token* button at the bottom and click it.
1. When a success message appears, click the *Proceed* button and then the *Use Token* button.
1. Back in Inferno, a new "User Action" dialog will appear requesting a Subscription. When it does, return to Postman,
   open the "Create Subscription Request" entry under the "Subscription Setup" folder in the collection,
   and click the *Send* button.
1. Back in Inferno, an **Approval Workflow Test** "User Action" will appear. When it does, return to Postman,
   open the "Prior Auth Request For Approval" entry under the "Approval Workflow Requests" folder in the
   collection, and click the *Send* button.
1. Back in Inferno, an attestation "User Action" will appear asking you to confirm that the prior auth
   request is listed as approved in the client app based on Inferno's response to the request. Search
   in the response returned to Postman for the string "Certified in total" which indicates the prior
   auth request was approved and click the link in Inferno indicating the attestation statement is true.
1. Next, a **Denial Workflow Test** "User Action" will appear. When it does, return to Postman,
   open the "Prior Auth Request For Denial" entry under the "Denial Workflow Requests" folder in the
   collection, and click the *Send* button.
1. Back in Inferno, an attestation "User Action" will appear asking you to confirm that the prior auth
   request is listed as denied in the client app based on Inferno's response to the request. Search
   in the response returned to Postman for the string "Not Certified" which indicates the prior
   auth request was denied and click the link in Inferno indicating the attestation statement is true.
1. Next, a **Pended Workflow Test** "User Action" will appear. When it does, return to Postman,
   open the "Prior Auth Request For Pended" entry under the "Pended Workflow Requests" folder in the
   collection, and click the *Send* button.
1. Search in the response returned to Postman for the string "Pending" which indicates the prior
   auth request was pended and a final decision will be made later. You'll use this information in
   a later attestation.
1. Meanwhile, Inferno sent a notification indicating that a final decision was made (5-10 seconds
   after the prior auth request). If interested in seeing the notification message, it can be found
   on the [notifications 
   page](https://subscriptions.argo.run/subscriptions/notifications-received?store=r4) for the 
   [Argonaut Subscriptions Reference Implementation](https://subscriptions.argo.run/), which
   hosts a notification endpoint that is used to receive Subscription notifications for this demo.
   Note that when looking for recent notifications, **Received** timestamps are in UTC which is
   5 hours ahead of Eastern Standard Time (4 hours ahead of Eastern Daylight Time).
1. Return to Postman, open the "Prior Auth Inquiry For Pended" entry under the "Pended Workflow Requests"
   folder in the collection, and click the *Send* button.
1. Search in the response returned to Postman for the string "Certified in total" which indicates the prior
   auth request was approved. You'll use this information in a later attestation.
1. Return to Inferno, scroll down in the "User Action" dialog and click the "click here to complete the test"
   link to allow Inferno to evaluate the pended workflow.
1. Two attestations will appear, the first stating that the prior auth request was registered in the
   client as pended and that it was subsequently finalized. You checked these above and can use the
   true link for both.
1. Two additional "User Action" dialogs will appear requesting additional `$submit` and `$inquire`
   requests to demonstrate must support elements. This demo does not have any additional requests
   and does not attempt to demonstrate all must support elements, so click the link to indicate
   you are done submitting requests for each. Note that requests submitted during the workflow section
   will be evaluated and you can inspect the results under test **3.2** *Demonstrate Element Support*
   to see both passing and failing tests.
1. Once Inferno finishes evaluating the requests, the test will complete allowing you to review the
   results, including warning and error messages as well as requests associated with each test.

#### Optional Demo Modifications

This demo uses `id-only` notifications for Pended workflow. To see a demonstration of `full-resource`
notifications, replace the string "id-only" in the "Create Subscription Request" entry under the 
"Subscription Setup" folder in the collection with the string "full-resource".

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