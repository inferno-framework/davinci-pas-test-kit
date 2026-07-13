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
    *   In the client suite session, check that the "User Action Required" asking for a Subscription Creation request has been replaced by a new one asking for an PAS request for an approval workflow. Once the new
    dialog appears, return to the server suite session (approval workflow requests will occur in the next step).
    *   The client suite has sent all expected notifications, so in the server suite session click the link to indicate that all requests have been sent, which will complete the test run.
5.  **Approval Workflow Execution**:
    *   In the server suite session, select the "**2.1** Successful Approval Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was approved. Click the statement indicating that it was.
    *   A new "User Action Required" dialog will appear asking for an PAS request for a denial workflow. These will be sent by the server tests in the next step.
6.  **Denial Workflow Execution**:
    *   In the server suite session, select the "**2.2** Successful Denial Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was denied. Click the statement indicating that it was.
    *   A new "User Action Required" dialog will appear asking for an PAS request for a pended workflow. These will be sent by the server tests in the next step.
7.  **Pended Workflow Execution**:
    *   In the server suite session, select the "**2.3** Successful Pended Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response. A "User Action Required" dialog will appear indicating that the server suite session is waiting for a Subscription notification indicating that the pended claim has been finalized. 5-10 seconds later, the client suite session will send the notification and the server suite test run will complete automatically.
    *   Once the server suite tests have completed, return to the client suite session and click the link in the current "User Action Dialog" to indicate that the workflow has completed.
    *   A second "User Action Required" dialog will appear asking for an attestation that the client system initially indicated that the submitted prior authorization request was pended. Click the statement indicating that it was.
    *   A third "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was approved once the notification was received. Click the statement indicating that it was.
    *   A fourth "User Action Required" dialog will appear asking for additional PAS requests to be made to evaluate must support element coverage. These will be sent by the server tests in the next step.
7.  **Must Support and Error Handling Execution**:
    *   In the server suite session, select the "**3** Demonstrate Element Support" group from the sidebar (typically found on the left side).
    *   Click the "Run All Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will send additional PAS submit and inquiry requests and evaluate the responses.
    *   Once execution completes, select the "**4** Demonstrate Error Handling" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will send additional PAS submit and inquiry requests and evaluate the responses.
    *   Once the server suite tests have completed, return to the client suite session and click the link in the current "User Action Dialog" to indicate that additional submit requests have been made.
    *   A second "User Action Required" dialog will appear asking for additional inquiry requests. These were made already, so click the link in the current "User Action Dialog" to indicate the requests have been made and the client test run will complete.
8.  **Review Results**:
    *   All tests have now been completed, so Inferno will display the results in the respective sessions.
    *   **Note**: Not all simulation inputs are fully conformant. Therefore, some failures or warnings will be included in the results.

## Basic Execution (v2.2.1)

Note that some client groups are not included in this execution. Additionally, the v2.2.1 server suite is a work
in progress, so 

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
    *   In the client session, select the "**10** Subscription Setup" group from the sidebar (typically found on the left side).
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
5.  **Approval Workflow Execution**:
    *   In the client session, select the "**11.1** Approval Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.1** Successful Approval Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was approved. Click the statement indicating that it was to complete the tests.
6.  **Denial Workflow Execution**: Repeat the same steps as in 5. for client group "**11.2** Denial Workflow" and server group "**2.2** Successful Denial Workflow".
7.  **Pended Workflow Execution**:
    *   In the client session, select the "**11.3** Pended Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.3** Successful Pended Workflow" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and then wait for a notification to be sent by the client suite. Wait for the server tests to complete.
    *   Once the server suite tests have completed, return to the client suite session. Click the link to indicate that all requests have been sent. A new "User Action Required" dialog will appear asking for an attestation that the client system indicated that the submitted prior authorization request was pended. Click the statement indicating that it was and then do the same in the next dialog asking about the final decision from the notification to complete the tests.
8.  **Claim Updates Execution**:
    *   In the client session, select the "**11.4** Claim Updates" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**2.4** Claim Updates" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a series of PAS request to the client suite session. Wait for the server tests to complete.
    *   Once the server suite tests have completed, return to the client suite sessio and confirm that they have completed as well.
9.  **Must Support Elements Execution**:
    *   In the client session, select the "**12** Must Support Elements" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**3** Demonstrate Element Support" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a series of PAS request to the client suite session and then verify that the requests and responses demonstrate all must support elements. Wait for the server tests to complete.
    *   Once the server suite tests have completed, return to the client suite session. Click the link to indicate that all requests have been sent. A new "User Action Required" dialog will appear asking for an attestation that the client system handled the $submit response must support elements appropriately. Click the statement indicating that it was and then do the same in the next dialog asking about the $inquire response must support elements to complete the tests.
10.  **Operation Failure Execution**:
    *   In the client session, select the "**13.1** Operation Failure" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution.
    *   A "User Action Required" dialog will appear indicating that Inferno is waiting for a $submit request.
    *   Return to the server suite test session.
    *   In the server suite session, select the "**4** Demonstrate Error Handling" group from the sidebar (typically found on the left side).
    *   Click the "Run Tests" button (typically found in the top-right).
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish. Click the "SUBMIT" button (usually at the bottom-right of the dialog) to start execution of the test run.
    *   Inferno will submit a PAS request to the client suite session and evaluate the response.
    *   Once the server suite tests have completed, return to the client suite session. A "User Action Required" dialog will appear asking for an attestation that the client system indicated that there was an error appropriately. Click the statement indicating that it was to complete the tests.