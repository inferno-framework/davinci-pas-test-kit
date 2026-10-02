# Da Vinci PAS Test Kit: Running the Client and Server tests against each other

During development and debugging, it can be useful to run the client and server suites
against each other to confirm behavior, design decisions, or bug fixes. The following
instructions can be used to do so. These instructions do not work when running the
test kit locally within Docker due to networking restrictions when running without a
dedicated hostname.

## Basic Execution (v2.0.1)

1.  **Setup the Client Test Session**:
    *   Open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.0.1" test kit.
    *   Choose the "Da Vinci PAS Client Suite v2.0.1".
    *   For the "Client Security Type" select the "Other Authentication" option.
    *   Click the "Start Testing" button to create a testing session.
    *   From the "Preset" dropdown menu (usually located in the top-left of the test suite page), select "Run Against the PAS Server Suite". This action will automatically populate various input fields, setting up the client suite's simulation of a PAS server by providing denied and pended responses for Inferno to return.
2.  **Setup the Server Test Session**:
    *   In another tab or window, open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.0.1" test kit.
    *   Choose the "Da Vinci PAS Server Suite v2.0.1".
    *   Click the "Start Testing" button to create a testing session.
    *   From the "Preset" dropdown menu (usually located in the top-left of the test suite page), select "Run Against the PAS Client Suite". This action will automatically populate various input fields, setting up the server suite's simulation of a PAS client by providing the URL of the client suite session's simulated server and requests for Inferno to make against it.
3.  **Begin Client Suite Execution**:
    *   Return to the client suite test session.
    *   Click the "Run All Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear asking for confirmation that authentication is supported. Click the link to indicate it is.
    *   A second "User Action Required" dialog will appear providing connection information. Click the link to confirm connectivity.
    *   A third "User Action Required" dialog will appear indicating that Inferno is waiting for a Subscription creation request, which will be sent by the server tests in the next step.
4.  **Subscription Setup Execution**:
    *   Return to the server suite test session.
    *   Select the "**1** Subscription Setup" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   A "User Action Required" dialog will appear indicating that the tests are waiting for Subscription interactions from the server, including a handshake notification based on the submitted Subscription. These
    requests will be sent by the client suite.
    *   In the client suite session, check that the "User Action Required" asking for a Subscription Creation request has been replaced by a new one asking for an PAS request for an approval scenario. Once the new dialog appears, return to the server suite session (approval scenario requests will occur in the next step).
    *   The client suite has sent all expected notifications, so in the server suite session click the link to indicate that all requests have been sent, which will complete the test run.
5.  **Approval Scenario Execution**:
    *   In the server suite session, select the "**2.1** Successful Approval Scenario" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was approved. Click the statement indicating that it was.
    *   A new "User Action Required" dialog will appear asking for an PAS request for a denial scenario. These will be sent by the server tests in the next step.
6.  **Denial Scenario Execution**:
    *   In the server suite session, select the "**2.2** Successful Denial Scenario" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was denied. Click the statement indicating that it was.
    *   A new "User Action Required" dialog will appear asking for an PAS request for a pended scenario. These will be sent by the server tests in the next step.
7.  **Pended Scenario Execution**:
    *   In the server suite session, select the "**2.3** Successful Pended Scenario" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response. A "User Action Required" dialog will appear indicating that the server suite session is waiting for a Subscription notification indicating that the pended claim has been finalized. 5-10 seconds later, the client suite session will send the notification and the server suite test run will complete automatically.
    *   Once the server suite tests have completed, return to the client suite session and click the link in the current "User Action Dialog" to indicate that the scenario has completed.
    *   A second "User Action Required" dialog will appear asking for an attestation that the client system initially indicated that the submitted prior authorization request was pended. Click the statement indicating that it was.
    *   A third "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was approved once the notification was received. Click the statement indicating that it was.
    *   A fourth "User Action Required" dialog will appear asking for additional PAS requests to be made to evaluate must support element coverage. These will be sent by the server tests in the next step.
7.  **Must Support and Error Handling Execution**:
    *   In the server suite session, select the "**3** Demonstrate Element Support" group from the sidebar (typically found on the left side).
    *   Click the "Run All Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will send additional PAS $submit and $inquire requests and evaluate the responses.
    *   Once execution completes, select the "**4** Demonstrate Error Handling" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will send additional PAS $submit and #inquire requests and evaluate the responses.
    *   Once the server suite tests have completed, return to the client suite session and click the link in the current "User Action Dialog" to indicate that additional submit requests have been made.
    *   A second "User Action Required" dialog will appear asking for confirmation that the $submit and #inquire responses were handled without error. Complete the attestation to complete the tests.
8.  **Review Results**:
    *   All tests have now been completed, so Inferno will display the results in the respective sessions.
    *   **Note**: Not all simulation inputs are fully conformant. Therefore, some failures or warnings will be included in the results.

## Basic Execution (v2.2.1)

Note that some client groups are not included in this execution. Additionally, the v2.2.1 server suite is a work
in progress, so some tests do not fully align yet.

1.  **Setup the Client Test Session**:
    *   Open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.2.1" test kit.
    *   Choose the "Da Vinci PAS Client Suite v2.2.1".
    *   For the "Client Security Type" select the "Other Authentication" option.
    *   Click the "Start Testing" button to create a testing session.
    *   From the "Preset" dropdown menu (usually located in the top-left of the test suite page), select "Run Against the PAS Server Suite". This action will automatically populate various input fields, setting up the client suite's simulation of a PAS server by providing denied and pended responses for Inferno to return.
2.  **Setup the Server Test Session**:
    *   In another tab or window, open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.2.1" test kit.
    *   Choose the "Da Vinci PAS Server Suite v2.2.1".
    *   Click the "Start Testing" button to create a testing session.
    *   From the "Preset" dropdown menu (usually located in the top-left of the test suite page), select "Run Against the PAS Client Suite". This action will automatically populate various input fields, setting up the server suite's simulation of a PAS client by providing the URL of the client suite session's simulated server and requests for Inferno to make against it.
3.  **Registration Execution**:
    *   Return to the client suite test session.
    *   Select the "**1** Client Registration" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear asking for confirmation that authentication is supported. Click the link to indicate it is.
    *   A second "User Action Required" dialog will appear providing connection information. Click the link to confirm connectivity and finish the group.
4.  **Subscription Setup Execution**:
    *   In the client session, select the "**8** Subscription Setup" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a Subscription creation request.
    *   Return to the server suite test session.
    *   Select the "**1** Subscription Setup" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   A "User Action Required" dialog will appear indicating that the tests are waiting for Subscription interactions from the server, including a handshake notification based on the submitted Subscription. These
    requests will be sent by the client suite.
    *   In the client suite session, check that the "User Action Required" asking for a Subscription Creation request has disappeared and the tests have completed.
    *   The client suite has sent all expected notifications, so in the server suite session click the link to indicate that all requests have been sent, which will complete the test run.
5.  **Approval Scenario Execution**:
    *   In the client session, select the "**9.1** Approval Response" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.1** Successful Approval Scenario" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was approved. Click the statement indicating that it was to complete the tests.
6.  **Denial Scenario Execution**: Repeat the same steps as in 5. for client group "**9.2** Denial Response" and server group "**2.2** Successful Denial Scenario".
7.  **Pended Scenario Execution**:
    *   In the client session, select the "**9.3** Pended Response" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.3** Successful Pended Scenario" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and then wait for a notification to be sent by the client suite. Once the server tests are waiting for a notification, return to the client session
    *   In the client suite session, a new "User Action Required" dialog will be present asking for an attestation that the client displays the Claim as pended. Confirm that it has.
    *   A third "User Action Required" dialog will appear indicating that Inferno will shortly send a notification. It will disappear within 10 seconds replaced by a fourth "User Action Required" dialog asking for confirmation that the client received the notification and displays the Claim as approved. Check the server session, the tests should have completed due to the receipt of the notification. Confirm in the client session that the Claim was approved and the run will complete.
8.  **Claim Updates Execution**:
    *   In the client session, select the "**9.4** Claim Updates" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.4** Claim Updates" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a series of PAS request to the client suite session. Wait for the server tests to complete.
    *   Once the server suite tests have completed, return to the client suite session where there will be a "User Action Required" dialog asking the testser to attest that the client handled the responses without error. Completing the attestation will finish the run.
9.  **Payer Modifications Execution**:
    *   In the client session, select the "**9.5** Payer Modifications" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.1** Successful Approval Scenario" group from the sidebar (typically found on the left side) to re-run it.
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session. Wait for the server tests to complete. Server test "**2.1.1.04** Server response includes the 'Approval' decision code in the ClaimResponse instance" should fail because "A6" (Modified) should be returned instead of "A1" (Certified in Total).
    *   Once the server suite tests have completed, return to the client suite session where there will be a "User Action Required" dialog asking the testser to attest that the client handled the responses without error and displayed the modifications. Completing the attestation will finish the run.
10. **Operation Failure Execution**:
    *   In the client session, select the "**9.6** Operation Failure" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**4** Demonstrate Error Handling" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit two PAS requests to the client suite session and evaluate the responses. The first will succeed as the client returns the expected OperationOutcome. The second will fail as Inferno will no longer be listening for requests.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that there was an error appropriately. Click the statement indicating that it was to complete the tests.
11.  **Processing Errors Execution**:
    *   In the client session, select the "**9.7** Processing Errors" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.1** Successful Approval Scenario" group from the sidebar (typically found on the left side) to re-run it.
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session. Wait for the server tests to complete. Server test "**2.1.1.04** Server response includes the 'Approval' decision code in the ClaimResponse instance" should fail because the client suites will return errors instead of items in the ClaimResponse.
    *   Once the server suite tests have completed, return to the client suite session where there will be a "User Action Required" dialog asking the testser to attest that the client handled the responses without error and displayed the errors to the appropriate users. Completing the attestation will finish the run.
12.  **Must Support Elements Execution**:
    *   In the client session, select the "**10** Must Support Elements" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for additional $submit and $inquire requests demonstrating must support items not previously demonstrated.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**3** Demonstrate Element Support" group from the sidebar (typically found on the left side).
    *   Click the "Run All Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a series of PAS request to the client suite session and then verify that the requests and responses demonstrate all must support elements. Wait for the server tests to complete.
    *   Once the server suite tests have completed, return to the client suite session. Click the link to indicate that all requests have been sent. A new "User Action Required" dialog will appear asking for an attestation that the client system handled the $submit and $inquire responses appropriately, displaying the results without error.
13.  **Visual Inspection and Attestation Execution**:
    *   In the client session, select the "**13** Visual Inspection and Attestation" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the inputs used to record the attestations. Update them as desired and then click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   The tests will complete with results based on the inputs provided.
