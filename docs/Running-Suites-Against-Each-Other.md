# Da Vinci PAS Test Kit: Running the Client and Server tests against each other

This document provides a step-by-step guide for running the Client and Server suites
of the the Da Vinci PAS Test Kit against each other to show their usage without
the need for a separate PAS implementation of either a client or server. This can be helpful
for development and debugging and demonstration.

## Basic Execution

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


