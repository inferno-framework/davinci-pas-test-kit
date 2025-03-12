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

All requests and responses will be checked for conformance to the PAS
IG requirements individually and used in aggregate to determine whether
required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

### Responses

Inferno contains basic logic to generate approval, denial, and pended responses, along with a
notification that a final decision was made, as a part of the above workflows.
These responses are based on examples available in the PAS Implementation Guide
and are conformant, but may not meet the needs of actual implementations. Thus,
testers may provide Inferno with specific responses for Inferno to echo. If responses
are provided, Inferno will check them for conformance to ensure that they demonstrate
a fully conformant exchange.

### Authentication

The [Privacy and Security section](https://hl7.org/fhir/us/davinci-pas/STU2/privacy.html) of the PAS
Implementation Guide states that payers must "require that the provider system authenticates"
itself when making PAS requests against the payer system. However, the specific method of authentication
is left to the Da Vinci HRex IG, which [provides recommendations and potential 
approaches](https://hl7.org/fhir/us/davinci-hrex/STU1/security.html#exchange-security) for
authentication, but does not require a specific one to be used. Inferno requires some
authentication approach to be used in order for it to be able to identify which incoming
requests are from the client under test.

Inferno's simulated payer server includes a simulation of two standard authentication approaches:
- SMART Backend Services
- UDAP B2B client credentials flow, including dynamic registration

Clients under test can register with the authorization server and request tokens for use
when making PAS requests. In this case, Inferno will verify that the client's interactions with
the simulated authorization server are conformant and that the provided tokens are used.

If the client under test does not support either of these standards-based methods of authentication, the tester
may instead attest to other authentication capabilities. In this case, the client will authenticate
by sending requests to dedicated PAS endpoints created by Inferno for use during the testing session.
To reduce configuration burden, the dedicated endpoints can be reused in subsequent sessions.

## Running the Tests

### Quick Start

The easiest way to run the tests is to perform an approval workflow using
inferno-generated responses and dedicated session-specific endpoints:

1. Select the "**3.1** Approval Workflow" group from the list at the left.
2. Click the "RUN TESTS" button in the upper right.
3. Click the "SUBMIT" button at the bottom right of the input dialog that appears.
4. Submit a PAS prior authorization request to the endpoint shown in the wait
   dialog that appears.
5. When another wait dialog appears, check your system to see whether Inferno's response
   was interpreted as an approval or not and click the appropriate link in the dialog.
6. Review the results including any errors or warnings found when checking the conformance
   of the request or the generated response.

Group "**3.2** Denial Workflow" can be run in the same manner. Other tests require additional setup:
- To run the "**3.3** Pended Workflow" group, first run the "**2** Subscription Setup" group, during
  which the client system will submit a Subscription so that Inferno knows how and where to
  send a notification that a decision has been rendered on a pended prior authorization request.
- To setup up standards-based authentication, run the "**1** Client Registration" group as described in the
  **Authentication Configuration** section below. This test must be run along with at least one
  workflow test using the configured authentication approach before running the
  "**5** Authentication Interactions" group.

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
   will be evaluated and you can inspect the results under test **3.2** Demonstrate Element Support
   to see both passing and failing tests.
1. Once Inferno finishes evaluating the requests, the test will complete allowing you to review the
   results, including warning and error messages as well as requests associated with each test.

#### Optional Demo Modifications

This demo uses `id-only` notifications for Pended workflow. To see a demonstration of `full-resource`
notifications, replace the string `id-only` in the "Create Subscription Request" entry under the 
"Subscription Setup" folder in the collection with the string `full-resource` (found in an extension
under the `_payload` element).

## Configuration Details

## Response and Notification Content

To assist in testers getting started with the PAS Client tests quickly, Inferno will generate
conformant mocked `$submit` and `$inquire` operation responses and Subscription notifications.
However, the simple mocked messages may not drive the workflows of real systems in a way that allows
them to demonstrate their implementation of the PAS specification. Thus, Inferno also allows each message
returned or initiated by Inferno to be specified by the tester. These messages must themselves be
conformant to PAS specification requirements and additional test requirements in order for a test run to
serve as a demonstration of a conformant implementation.

The rest of this section provides details on how Inferno determines the content to use in responses
and notifications.

### Inferno Modifications of Tester-provided Responses and Notifications

Requests provided by testers will be modified by Inferno to try and populate details that testers won't
know ahead of time. These modifications fall into two categories:
- **Timestamps**: creation timestamps, such as those on Bundles, ClaimResponses, and event notifications,
  will be updated or populated by Inferno so that they are in sync with the time the message is sent.
- **Resource Ids**: some resource ids will not be known ahead of time and will be added or updated by Inferno 
  including
  - *Claim Id*: if the tester provides a `$submit` or `$inquire` response with `ClaimResponse.request` populated,
    then Inferno will update it with the fullUrl of the Claim provided in the request. This avoids the need for 
    testers to know the Claim Id ahead of time which may be difficult for some systems.
  - *ClaimResponse Id*: if the tester provides a Notification but has Inferno generate the `$submit` response,
    then Inferno will update the focus to use the ClaimResponse id that it generates.

If the tester provides an input that is malformed in some way such that Inferno cannot get the details
that Inferno needs to make the modifications, then the raw input will be used.

### Response and Notification Correspondence Requirements

Beyond the minor modifications described above, Inferno does not modify provided content to ensure that
they are consistent with each other or the time they are executed. For example, in the pended
workflow, it is up to the tester to ensure that if they provide responses for the `$submit` and `$inquire`
operations that they share whatever details, such as identifiers, needed to connect them together and drive
the workflow in their system. Timestamps not associated with messaging time such as when a prior authorization
response is valid are also not modified by Inferno. Unlike details that Inferno modifies as described above,
testers should have control over and/or knowledge of the necessary details and values to construct consistent
and working messages for Inferno to use.

### Tester-provided Response and Notification Inputs

The following test inputs control Inferno messaging behavior:
- **Claim approved response JSON**: If populated, this is used in the "**2.2.1** Approval Workflow" group
  to respond to `$submit` requests. The response needs to indicate to the system that the prior auth request has
  been approved.
- **Claim denied response JSON**: If populated, this used in the "**2.2.2** Denial Workflow" group
  to respond to `$submit` requests. The response needs to indicate to the system that the prior auth request has
  been denied.
- **Claim pended response JSON**: If populated, this used in the "**2.2.3** Pended Workflow" group
  to respond to `$submit` requests. The response needs to indicate to the system that the prior auth request has
  been pended.
- **Claim updated notification JSON**: If populated, this used in the "**2.2.3** Pended Workflow" group
  as the event notification sent for the Subscription indicating that a decision has been finalized for the
  pended prior auth request. The content of the notification needs to match the details of the Subscription
  provided in the "**2.1** Subscription Setup" group.
- **Inquire approved response JSON**: If populated, this used in the "**2.2.3** Pended Workflow"
  group to respond to `$inquire` requests. The response needs to indicate to the system that the
  prior auth request has been approved.

### Generation Logic

When generating responses and notifications, Inferno uses the following logic. These conform to the
requirements of the PAS specification, but may not make sense in an actual workflow.
- **`$submit` and `$inquire` responses**: these responses are created mostly from the incoming request, specific details include:
  - The Patient, insurer Organization, and requestor entity instances are pulled into the response
    Bundle and referenced in the `patient`, `insurer`, and `requestor` elements respectively.
    Note that get found by following references found in the submitted Claim instance. If relative
    references are used in the Claim, the Claim entry `fullUrl` needs to be a absolute reference
    and not a UUID, else the entries won't get pulled in correctly.
  - In the ClaimResponse, the `identifier`, `type`, `status`, and `use` elements are pulled
    in from the Claim in the request.
  - The `Bundle.timestamp` and `ClaimResponse.created` timestamps are populated using the current time.
  - The `ClaimResponse.outcome` is hardcoded to `complete`.
  - For each `item` entry in the request Claim, a `ClaimResponse.item` entry is created with the
    `itemSequence` value copied over, `itemPreAuthIssueDate` and `itemPreAuthPeriod` extensions 
    added using the current date and a month starting on the current date respectively,
    and an adjudication entry with a `category` of `submitted` that contains the `reviewAction` extension with a
    `reviewActionCode` that matches the current workflow: `A1` ("Certified in total") for approval,
    `A3` ("Not Certified") for denial, and `A4` ("Pending") for pending.
- **Notification Bundle**: Inferno supports mocking both `id-only` and `full-resource` notifications.
  The following details are relevant:
  - Inferno pulls in details from the Subscription created for the test session to use in
   creating the Notification, including the `topic` and the `subscription` reference.
  - Inferno hardcodes the `status` as `active` and the `type` as `event-notification`.
  - Inferno will always include a single `notification-event` entry with a `timestamp` of the current
    time and with a `focus` that points to the ClaimResponse returned on the `$submit`.
    If it cannot find the ClaimResponse reference from the `$submit` response returned
    by Inferno, it will generate a random UUID (which isn't likely to work correctly when received).
  - The subscription's `events-since-subscription-start` and the event's `event-number` will always
    be 1 as Inferno is not able to track notifications across multiple sessions or runs.
  - When generating a `full-resource` notification, Inferno will include `additional-context`
    references for each entry in the `$submit` response Bundle other than the ClaimResponse
    (which is already in the `focus`). Then it will include Notification Bundle entries for
    each instance in the `$submit` response Bundle, including the ClaimResponse, with `reviewActionCode`
    extensions updated to indicate approval using code `A1` ("Certified in total") for approval.

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

- *Cannot verify the correct usage of X12-based terminology*: terminology requirements for all elements bound to X12
value sets will not be validated.
- *Cannot verify the meaning of codes*: validation that a given response conveys something specific, e.g., approval
or pending, is not performed.
- *Cannot verify matching semantics on inquiries*: no checking of the identity of the ClaimResponse returned for an
inquiry, e.g., that it matches the input or the original request.

These limitations may be removed in future versions of these tests. In the meantime, testers should consider these
requirements to be verified through attestation and should not represent their systems to have passed these tests
if these requirements are not met.

### Subscription Details

Subscription details in the PAS 2.0.1 specification are relatively underspecified and the
[published 2.1.0 version of the 
specification](https://hl7.org/fhir/us/davinci-pas/STU2.1/specification.html#subscription) 
makes significant changes, including requiring `full-resource` and updating details such as
the filter criteria.

Based on the immaturity of the 2.0.1 requirements around Subscriptions, these tests implement and check for
the mechanics of Subscriptions and notifications, but do not look closely at the details. For example,
`id-only` and `full-resource` are supported and the filter criteria format is not checked. Future versions
of these tests may be more stringent.

Additionally, to test Subscriptions and pending workflows, a new Subscription must be created for each
test session, which may require testers to re-initialize previously-created Subscriptions. Future versions
of these tests may relax this requirement and feedback on whether this would reduce burden and how this
might look are welcome.

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