# Da Vinci PAS Test Kit: Client Testing Walkthrough

This document provides a step-by-step guide for running the Da Vinci PAS Test Kit to test a **client system**. In this scenario, Inferno acts as the PAS server.

## Quick Start

To execute a simple set of tests with minimal setup and input, perform an approval workflow using
inferno-generated responses and dedicated session-specific endpoints with the following steps:

1. Create a Da Vinci PAS Client Suite v2.0.1 session using the "Other Authentication" option
   for the Client Security Type.
1. Select the "Client Registration" group from the list at the left and and click
   the "RUN TESTS" button in the upper right.
1. Optionally provide a value for the **Session-specific URL path extension** input to
   specify the extra path for the dedicated session endpoint or leave blank to let
   Inferno generate a value for you. Then click the "SUBMIT" button at the bottom right.
1. Attest to an alternate authentication approach in the wait dialog that appears and
   then configure your client to connect to the Inferno FHIR server subsequently displayed
   and click the link continue.
1. Select the "Approval Workflow" group from the list at the left and click
   the "RUN TESTS" button in the upper right.
1. Click the "SUBMIT" button at the bottom right of the input dialog that appears.
1. Submit a PAS prior authorization request to the endpoint shown in the wait
   dialog that appears.
1. When another wait dialog appears, check your system to see whether Inferno's response
   was interpreted as an approval or not and click the appropriate link in the dialog.
1. Review the results including any errors or warnings found when checking the conformance
   of the request or the generated response.

Group "Denial Workflow" can be run in the same manner. To run the "Pended Workflow" group,
first run the "Subscription Setup" group, during which the client system will submit a
Subscription so that Inferno knows how and where to send a notification that a decision has
been rendered on a pended prior authorization request. Then proceed to execute the 
"Pended Workflow" group and follow the instructions in the dialogs that appear.

### Postman-based Demonstration

If you do not have a PAS client but would like to try the tests out, you can use
[this postman collection](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/docs/demo/PAS%20Client%20Suite%20Demonstration.postman_collection.json)
to make requests against Inferno and see the mocked responses provided by Inferno. To use, load
the collection into the [Postman app](https://www.postman.com/downloads/) and follow these steps:

1. Start a Da Vinci PAS Client Suite v2.0.1 session from the [PAS Test Kit page on 
   inferno.healthit.gov](https://inferno.healthit.gov/test-kits/davinci-pas/),
   choosing the "Other Authentication" option for the Client Security Type.
2. Click the *Run All Tests* button in the upper right hand corner of the suite.
3. Client Registration
   - In the **Session-specific URL path extension** input, put a short alpha string, such as `demo`
   - In Postman, select the *PAS Client Suite Demonstration* Collection in postman and go to the "Variables" tab 
     (see the collection's Overview tab for more details on what the variables control).
   - In the current value for the **session_url_path** variable, put the same value as in the
     **Session-specific URL path extension** input, surrounded by `/`, e.g., `/demo/` and
     save the collection.
   - Back in Inferno, click the "SUBMIT" button and click the links to continue the tests
     in the next two wait dialogs until a **Subscription Creation Test** wait dialog appears.
1. In Postman, select the *Create Subscription Request* in the *Subscription Setup* folder
   and click the "Send" button in the upper right.
1. Back in Inferno, the wait dialog should disappear and a new **Approval Workflow Test** wait
   dialog will appear.
1. In Postman, select the *Prior Auth Request For Approval* in the *Approval Workflow* folder
   and click the "Send" button in the upper right.
1. Back in Inferno, the wait dialog should disappear and a new attestation wait dialog will
   appear asking to confirm the system's interpretation of the "Approved" response. Check that
   the response from the last step in Postman contains the string "Certified in total" and respond
   to the attestation. The wait dialog should disappear and a new **Denial Workflow Test** wait
   dialog will appear.
1. In Postman, select the *Prior Auth Request For Denial* in the *Denial Workflow* folder
   and click the "Send" button in the upper right.
1. Back in Inferno, the wait dialog should disappear and a new attestation wait dialog will
   appear asking to confirm the system's interpretation of the "Denied" response. Check that
   the response from the last step in Postman contains the string "Not Certified" and respond
   to the attestation. The wait dialog should disappear and a new **Pended Workflow Test** wait
   dialog will appear.
1. In Postman, select the *Prior Auth Request For Pended* entry under the *Pended Workflow* folder in the
   and click the "Send" button in the upper right.
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
1. In Postman, select the *Prior Auth Inquiry for Pended* entry under the *Pended Workflow* folder in the
   and click the "Send" button in the upper right.
1. Search in the response returned to Postman for the string "Certified in total" which indicates the prior
   auth request was approved. You'll use this information in a later attestation.
1. Back in Inferno, scroll down in wait dialog and click the "click here to complete the test"
   link to allow Inferno to evaluate the pended workflow.
1. The next two attestations ask whether the system displayed the claim as pended and approved at the
   appropriate points in the workflow. Attest based on whether the correct strings were found in the
   responses in the previous steps.
1. Two additional "User Action" dialogs will appear requesting additional `$submit` and `$inquire`
   requests to demonstrate must support elements. This demo does not have any additional requests
   and does not attempt to demonstrate all must support elements, so click the link to indicate
   you are done submitting requests for each. Note that requests submitted during the workflow section
   will be evaluated and you can inspect the results under the Demonstrate Element Support test
   to see both passing and failing tests.
1. Once Inferno finishes evaluating the requests, the test will complete allowing you to review the
   results, including warning and error messages as well as requests associated with each test.

The tests are expected to pass with the exception of the Must Support tests.

#### Optional Demo Modification: full-resource Subscription

This demo uses `id-only` notifications for Pended workflow. To see a demonstration of `full-resource`
notifications, replace the string `id-only` in the "Create Subscription Request" entry under the 
"Subscription Setup" folder in the collection with the string `full-resource` (found in an extension
under the `_payload` element).

#### Optional Demo Modification: SMART Backend Services Auth

To use SMART Backend Services with the demo, choose the "SMART Backend Services" Client Security Type
option and replace the 3. Client Registration steps above with the following:

- In the **SMART JSON Web Key Set (JWKS)** input, put `https://inferno.healthit.gov/suites/custom/smart_stu2_2/.well-known/jwks.json`
- In the **Client Id** input, put `pas_demo_smart`
- Click the **SUBMIT** button
- A wait dialog will display asking the tester to confirm configuration of the client. Note the
  FHIR endpoint and client id details
- Start an instance of the SMART App Launch STU2.2 test suite.
- Select the **3** Backend Services group from the list at the left and the click the "RUN TESTS"
  button in the upper right.
- Fill in the following input values and then click "SUBMIT":
  - **FHIR Endpoint**: from the wait dialog in the PAS Client suite
  - **Scopes**: any scope string, e.g., `system/*.rs`
  - **Client Id**: same value as in the corresponding input to the PAS Client tests, also displayed
    in the wait dialog
- Find the access token to use for the data access request by opening test **3.2.05** Authorization
  request succeeds when supplied correct information, click on the "REQUESTS" tab, clicking on the "DETAILS"
  button, and expanding the "Response Body". Copy the "access_token" value, which will be a ~100 character
  string of letters and numbers (e.g., eyJjbGllbnRfaWQiOiJzbWFydF9jbGllbnRfdGVzdF9kZW1vIiwiZXhwaXJhdGlvbiI6MTc0MzUxNDk4Mywibm9uY2UiOiJlZDI5MWIwNmZhMTE4OTc4In0)
- In Postman, select the *PAS Client Suite Demonstration* Collection in postman and go to the "Variables" tab 
  (see the collection's Overview tab for more details on what the variables control).
- In the current value for the **access_token** variable, put access token value copied from the SMART tests.
  Make sure that the **session_url_path** variable has a current value of `/`.
- Back in Inferno, click link in the wait dialog confirming the configuration to continue the tests.
- A **Subscription Creation Test** wait dialog will appear.

Continue the tests according to step 4 around Subscription creation in the above instructions.

In this demonstration, the "Verify SMART Token Requests" test will also fail due to invalid
token requests sent intentionally by the SMART Backend Services server tests.

#### Optional Demo Modification: UDAP Client Credentials Auth

To use the UDAP Client Credentials with the demo, choose the "UDAP B2B Client Credentials" Client
Security Type option and replace the 3. Client Registration steps above with the following:

- In the **UDAP Client URI** input, put `http://localhost:4567/custom/udap_security/fhir`
- Click the **SUBMIT** button and a wait dialog will display asking the tester to perform UDAP dynamic
  registration. Note the FHIR server endpoint displayed in the dialog.
- Start an instance of the UDAP Security Server test suite.
- Select the "Demo: Run Against the UDAP Security Client Suite" preset from the dropdown in the upper left.
- Select the **2** UDAP Client Credentials Flow group from the list at the left and the click the "RUN ALL TESTS"
  button in the upper right.
- Update the **FHIR Server Base URL** input value to be the FHIR server endpoint from the wait dialog
  in the PAS Client suite and then click "SUBMIT"
- Once the tests have completed, find the access token to use for the data access request by opening
  test **2.3.01** OAuth token exchange request succeeds when supplied correct information, click
  on the "REQUESTS" tab, clicking on the "DETAILS" button, and expanding the "Response Body".
  Copy the "access_token" value, which will be a ~100 character string of letters and numbers (e.g., eyJjbGllbnRfaWQiOiJzbWFydF9jbGllbnRfdGVzdF9kZW1vIiwiZXhwaXJhdGlvbiI6MTc0MzUxNDk4Mywibm9uY2UiOiJlZDI5MWIwNmZhMTE4OTc4In0)
- In Postman, select the *PAS Client Suite Demonstration* Collection in postman and go to the "Variables" tab 
  (see the collection's Overview tab for more details on what the variables control).
- In the current value for the **access_token** variable, put access token value copied from the SMART tests.
  Make sure that the **session_url_path** variable has a current value of `/`.
- In the PAS Client suite tab, click the link in the wait dialog to continue the tests. Do the same
  for the next wait dialog that appears until a **Subscription Creation Test** wait dialog appears.

Continue the tests according to step 4 around Subscription creation in the above instructions.

In this demonstration, the "Verify UDAP Client Credentials Token Requests" test may fail due
to expired signatures if the test session has taken long enough.
