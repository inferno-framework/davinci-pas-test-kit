# Da Vinci PAS Test Kit: Client Testing Walkthrough

This document provides a step-by-step guide for running the Da Vinci PAS Test Kit to test a **client system**. In this scenario, Inferno acts as the PAS server.

## 1. Quick Start (Approval Workflow Example)

This example demonstrates a basic approval workflow with Inferno-generated responses and session-specific endpoints.

1.  **Navigate to Inferno**: Open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.0.1" test kit.
2.  **Create a Test Session**:
    *   Choose the "Da Vinci PAS Client Suite v2.0.1".
    *   For "Client Security Type", select "Other Authentication".
3.  **Run Client Registration Group**:
    *   Select the "Client Registration" group from the test list on the left.
    *   Click the "RUN TESTS" button (top-right).
    *   Optionally, provide a value for **Session-specific URL path extension** (e.g., `myclienttest`) or leave it blank for Inferno to generate one. This creates a unique endpoint for your test session.
    *   Click "SUBMIT" (bottom-right).
4.  **Attest and Configure Client**:
    *   A dialog will appear asking you to attest to an alternate authentication approach. Click the appropriate link to proceed.
    *   Inferno will then display the FHIR server endpoint (e.g., `http://<your_inferno_address>/custom/pas_client_suite_v201/<session_id_or_extension>/fhir`).
    *   Configure your client system to use this Inferno FHIR server endpoint.
    *   Click the link in the dialog to continue.
5.  **Run Approval Workflow Group**:
    *   Select the "Approval Workflow" group from the test list.
    *   Click "RUN TESTS".
    *   Review any inputs (usually none needed for default Inferno-generated responses) and click "SUBMIT".
6.  **Client Action: Submit Prior Auth Request**:
    *   A dialog will appear, waiting for your client to submit a PAS prior authorization request to the displayed endpoint (e.g., `http://<your_inferno_address>/custom/pas_client_suite_v201/<session_id_or_extension>/fhir/Claim/$submit`).
    *   Using your client system, create and submit a prior authorization request.
7.  **Client Action: Interpret Response**:
    *   After your client submits the request, Inferno will respond (simulating an approval).
    *   Another dialog will appear in Inferno, asking you to check your client system to see if the response was interpreted as an approval.
    *   Confirm in your client system and then click the appropriate link in the Inferno dialog ("The system indicated that the Claim was approved." or "The system indicated that the Claim was not approved.").
8.  **Review Results**:
    *   Inferno will display the test results. Review any errors or warnings.

**To run other workflows (Denial, Pended):**

*   **Denial Workflow**: Follow similar steps as Approval, selecting the "Denial Workflow" group.
*   **Pended Workflow**:
    1.  First, run the "Subscription Setup" group. Your client will need to submit a `Subscription` resource to Inferno so it knows where to send notifications.
    2.  Then, run the "Pended Workflow" group, following the on-screen instructions. This typically involves:
        *   Client submits a prior auth request.
        *   Inferno responds with a "pended" status.
        *   Inferno sends a notification (simulating a final decision) to the endpoint specified in the client's `Subscription`.
        *   Client makes an inquiry (`$inquire`) to get the final decision.
        *   Attestations in Inferno regarding the client's interpretation of pended and final statuses.

## 2. Client Testing with Postman (Demonstration)

If you don't have a PAS client ready, you can use the provided Postman collection to simulate client requests and interact with Inferno.

*   **Postman Collection**: [PAS Client Suite Demonstration.postman_collection.json](./demo/PAS%20Client%20Suite%20Demonstration.postman_collection.json)
*   **Postman App**: Download from [postman.com/downloads](https://www.postman.com/downloads/)

**Steps:**

1.  **Start Inferno Session**:
    *   In Inferno, start a "Da Vinci PAS Client Suite v2.0.1" session.
    *   Choose "Other Authentication" for Client Security Type.
2.  **Run All Tests (Initial Setup)**:
    *   In Inferno, click the "Run All Tests" button (top-right).
3.  **Client Registration (Inferno & Postman)**:
    *   **Inferno**:
        *   In the **Session-specific URL path extension** input, enter a short string (e.g., `postmandemo`).
    *   **Postman**:
        *   Import and select the *PAS Client Suite Demonstration* collection.
        *   Go to the "Variables" tab of the collection.
        *   Set the `base_url` variable's CURRENT VALUE to your Inferno instance's address (e.g., `http://localhost:4567` or `https://inferno.healthit.gov`).
        *   Set the `session_url_path` variable's CURRENT VALUE to the path extension you used in Inferno, surrounded by slashes (e.g., `/postmandemo/`).
        *   Save the Postman collection changes.
    *   **Inferno**:
        *   Click "SUBMIT".
        *   Click through the attestation/confirmation dialogs until a **Subscription Creation Test** wait dialog appears.
4.  **Subscription Creation (Postman & Inferno)**:
    *   **Postman**:
        *   In the *Subscription Setup* folder, select the *Create Subscription Request*.
        *   Review the request body (it typically points to a public endpoint like `https://subscriptions.argo.run/...` for demo purposes).
        *   Click "Send".
    *   **Inferno**:
        *   The wait dialog should advance. An **Approval Workflow Test** wait dialog will appear.
5.  **Approval Workflow (Postman & Inferno)**:
    *   **Postman**:
        *   In the *Approval Workflow* folder, select *Prior Auth Request For Approval*.
        *   Click "Send".
    *   **Inferno**:
        *   The wait dialog advances. An attestation dialog appears.
        *   Check the Postman response (it should indicate approval, e.g., contain "Certified in total").
        *   Respond to the attestation in Inferno. A **Denial Workflow Test** wait dialog appears.
6.  **Denial Workflow (Postman & Inferno)**:
    *   **Postman**:
        *   In the *Denial Workflow* folder, select *Prior Auth Request For Denial*.
        *   Click "Send".
    *   **Inferno**:
        *   The wait dialog advances. An attestation dialog appears.
        *   Check the Postman response (it should indicate denial, e.g., contain "Not Certified").
        *   Respond to the attestation in Inferno. A **Pended Workflow Test** wait dialog appears.
7.  **Pended Workflow (Postman & Inferno)**:
    *   **Postman - Submit Pended Request**:
        *   In the *Pended Workflow* folder, select *Prior Auth Request For Pended*.
        *   Click "Send".
        *   Note the response in Postman (should indicate "Pending").
    *   **Inferno - Notification (Automatic)**:
        *   Inferno will simulate sending a notification (after a short delay) to the endpoint defined in the Subscription (e.g., the Argonaut Subscriptions RI).
    *   **Postman - Inquire for Final Decision**:
        *   In the *Pended Workflow* folder, select *Prior Auth Inquiry for Pended*.
        *   Click "Send".
        *   Note the response in Postman (should indicate the final decision, e.g., "Certified in total" for approval).
    *   **Inferno - Complete Pended Workflow**:
        *   In the Inferno wait dialog, scroll down and click the "click here to complete the test" link.
        *   Respond to the subsequent attestations based on the "Pending" and final "Approved" statuses observed in Postman responses.
8.  **Must Support Tests (Inferno)**:
    *   Two "User Action" dialogs will appear for `$submit` and `$inquire` to demonstrate must-support elements. The demo Postman collection doesn't provide exhaustive examples for all must-support elements.
    *   For each dialog, click the link indicating you are done submitting requests. Requests from earlier workflow steps will still be evaluated.
9.  **Review Final Results**:
    *   Once Inferno finishes, review the complete test results. Some Must Support tests might fail if the demo requests didn't cover all elements.

Refer to the [Client Test Suite Description](./client_suite_description_v201.md) for more details on authentication options (SMART, UDAP) and providing custom responses.
