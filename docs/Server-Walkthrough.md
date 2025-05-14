# Da Vinci PAS Test Kit: Server Testing Walkthrough

This document provides a step-by-step guide for running the Da Vinci PAS Test Kit to test a **server system (payer)**. In this scenario, Inferno acts as the PAS client.

## 1. Quick Start (Using Public Reference Server Example)

This example uses pre-configured inputs to test against the public Da Vinci PAS reference implementation. This is useful for understanding the test flow.

1.  **Navigate to Inferno**: Open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.0.1" test kit.
2.  **Create a Test Session**:
    *   Choose the "Da Vinci PAS Server Suite v2.0.1".
3.  **Select Preset**:
    *   From the "Preset" dropdown menu (usually located in the top-left of the test suite page), select "Prior Authorization Support Reference Implementation".
    *   This action will automatically populate various input fields, such as the FHIR server endpoint and sample request payloads, with values appropriate for the public reference server.
4.  **Run All Tests**:
    *   Click the "Run All Tests" button (typically found in the top-right).
5.  **Submit Inputs**:
    *   A dialog will appear showing the pre-filled inputs from the preset. You can review them if you wish.
    *   Click the "SUBMIT" button (usually at the bottom-right of the dialog).
6.  **Monitor Execution**:
    *   Inferno will begin executing the test sequences against the configured reference server. This process includes:
        *   **Subscription Setup**: Inferno sends a `Subscription` resource (defined in the preset inputs) to the server. The server is expected to process this and be ready to send notifications to an Inferno-hosted endpoint when relevant events occur.
        *   **Core Workflows (Approval, Denial, Pended, Error)**: Inferno sends various `$submit` and `$inquire` FHIR Bundle requests (also from preset inputs) to the server. It then validates the server's responses for conformance and correctness according to the expected workflow outcome.
        *   For the pended workflow, after sending a request that should result in a pended status, Inferno will wait for a notification from the server (triggered by the earlier `Subscription`) before proceeding with a `$inquire` request to get the final decision.
7.  **Review Results**:
    *   Once all tests have completed, Inferno will display the results.
    *   **Note**: The public reference server may not always be perfectly aligned with the STU2 version of the PAS IG that these tests target. Therefore, some failures or warnings might be observed when testing against it. This is normal and primarily serves to demonstrate the test execution flow.

## 2. Testing Your Own Server

This section details how to configure and run the tests against your own PAS server implementation.

1.  **Navigate to Inferno**: Open your Inferno instance and select "Da Vinci Prior Authorization Support (PAS) v2.0.1" test kit.
2.  **Create a Test Session**:
    *   Choose the "Da Vinci PAS Server Suite v2.0.1".
3.  **Configure Inputs**:
    *   When you select a specific test group (e.g., "Approval Workflow") or click "Run All Tests", an input dialog will appear. You **must** provide the following information tailored to your server:
        *   **FHIR Server Endpoint URL**: The base FHIR URL of your PAS server (e.g., `https://your-pas-server.com/fhir`). Inferno will append `/Claim/$submit`, `/Claim/$inquire`, and `/Subscription` to this base URL.
        *   **OAuth Credentials / Access Token**: If your server requires OAuth 2.0 authentication for its PAS endpoints, provide a valid Bearer token here. Inferno will include this token in the `Authorization` header of all requests it makes to your server.
        *   **PAS Submit Request Payload for Approval Response**: A complete JSON-encoded FHIR Bundle. This bundle should be a `$submit` request that, when sent to your server, is expected to result in a prior authorization approval.
        *   **PAS Submit Request Payload for Denial Response**: A JSON FHIR Bundle for a `$submit` request that should lead to a denial from your server.
        *   **PAS Submit Request Payload for Pended Response**: A JSON FHIR Bundle for a `$submit` request that should cause your server to return a pended status.
        *   **PAS Inquire Request Payload for Pended Claim**: A JSON FHIR Bundle for a `$inquire` request. This request should be for the claim that was previously pended, and your server is expected to return the final decision (e.g., approval or denial).
        *   **PAS Submit Request Payload for Error Response** (Optional but Recommended): A JSON FHIR Bundle for a `$submit` request that is malformed or should otherwise cause your server to return an error (typically an `OperationOutcome`).
        *   **Additional PAS Submit Request Payloads** (Optional): A JSON array of JSON FHIR Bundles (e.g., `[bundle1, bundle2]`). These are used to test must-support elements more comprehensively by submitting varied requests.
        *   **Additional PAS Inquire Request Payloads** (Optional): Similar to the above, but for `$inquire` operations.
        *   **Pended Prior Authorization Subscription**: A JSON FHIR `Subscription` resource body. Inferno will POST this to your server's `/Subscription` endpoint. This `Subscription` should be crafted so that your server sends notifications to Inferno when the pended prior authorization request (from "PAS Submit Request Payload for Pended Response") is updated with a final decision. Inferno will automatically modify the `channel.endpoint` in this provided `Subscription` to its own dynamically generated notification listener URL.
        *   **Notification Access Token**: If your server, when sending a notification *to* Inferno's endpoint, requires an `Authorization` header with a Bearer token, provide that token here.
4.  **Run Tests**:
    *   After configuring the inputs, select a specific test group or "Run All Tests".
    *   Click the "RUN TESTS" button.
    *   If you haven't already, fill in all required inputs in the dialog.
    *   Click "SUBMIT".
5.  **Monitor and Ensure Server Readiness**:
    *   Inferno will begin sending requests to your server. Ensure your server is running, accessible from the Inferno instance, and correctly configured to handle PAS requests.
    *   **For the Pended Workflow**:
        *   Your server must successfully process the `Subscription` resource POSTed by Inferno.
        *   When the claim submitted via "PAS Submit Request Payload for Pended Response" is finalized by your server's internal logic, your server must send a notification (as per the active `Subscription`) to the endpoint Inferno provided (visible in the test execution logs or `Subscription` resource details).
        *   Inferno will wait for this notification before sending the "PAS Inquire Request Payload for Pended Claim".
6.  **Review Results**:
    *   After the tests complete, carefully review the results in Inferno. Pay close attention to any failures or warnings, as they indicate potential non-conformance with the PAS IG. The details of each test execution, including requests sent and responses received, can be inspected.

Refer to the [Server Test Suite Description](../tree/main/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md) for more in-depth explanations of each input field, authentication, and specific testing limitations.
