# Error Handling Groups — Manual Testing Guide

This folder contains PAS Request Bundle JSON files to use as the `$submit` request body when manually testing the v2.2.1 client suite **Error Handling** groups.

## Overview

The two error handling groups — **Operation Failure** and **Processing Errors** — work by having Inferno act as the PAS server. Each group waits for a `$submit` POST from the client under test. You use Postman (or curl) to play that role and trigger the test to advance.

## Prerequisites

1. Inferno is running locally (or on a known host).
2. You have loaded the `pas_client_v221_run_against_pas_server` preset, which pre-populates the required response inputs (`operation_failure_operation_outcome`, `operation_failure_http_status`, `processing_error_response`).
3. Postman is installed and open.

---

## Operation Failure Group

**What this tests:** Inferno returns a 4XX HTTP status and an OperationOutcome to the client. The test verifies the client handles the error appropriately.

### Steps

1. In Inferno, navigate to the **Error Handling → Operation Failure** group and start the first test ("Client submits a claim and handles an operation failure").
2. A modal will appear with a wait message. Copy the `$submit` URL shown — it will look like:
   ```
   POST http://<inferno-host>/custom/davinci_pas_client_suite_v221/<session_path>/Claim/$submit
   ```
3. In Postman:
   - Set the method to **POST**.
   - Paste the URL from step 2.
   - Under **Headers**, add:
     - `Content-Type: application/fhir+json`
   - Under **Body**, select **raw → JSON** and paste the contents of `operation_failure_submit_request.json`.
4. Send the request. Inferno will respond with the OperationOutcome and HTTP 400 (or the status you configured), and the test will automatically advance.
5. The **OperationOutcome validation** test runs automatically — no action needed.
6. The **Attestation** test will present two links. Click **true** if the client system surfaced the error details to the appropriate users, or **false** otherwise.

---

## Processing Errors Group

**What this tests:** Inferno returns an HTTP 200 response with a PAS Response Bundle containing `ClaimResponse.error` entries. The test verifies the client handles the business-level errors appropriately.

### Steps

1. In Inferno, navigate to the **Error Handling → Processing Errors** group and start the first test ("Client submits a claim and handles a response containing processing errors").
2. A modal will appear with a wait message. Copy the `$submit` URL shown — it will look like:
   ```
   POST http://<inferno-host>/custom/davinci_pas_client_suite_v221/<session_path>/Claim/$submit
   ```
3. In Postman:
   - Set the method to **POST**.
   - Paste the URL from step 2.
   - Under **Headers**, add:
     - `Content-Type: application/fhir+json`
   - Under **Body**, select **raw → JSON** and paste the contents of `processing_error_submit_request.json`.
4. Send the request. Inferno will respond with the processing error bundle (HTTP 200) and the test will automatically advance.
5. The **Request Bundle validation** test runs automatically — no action needed.
6. The **Response Bundle validation** test runs automatically — no action needed.
7. The **Attestation** test will present two links. Click **true** if the client system surfaced the ClaimResponse error details to the appropriate users, or **false** otherwise.

---

## Notes

- Both JSON files in this folder are conformant PAS Request Bundles. They are identical in content — the difference in test behavior comes entirely from Inferno's configured response, not the request body.
- If you want to test with a different request payload, replace the body with any valid PAS Request Bundle (profiled against `profile-pas-request-bundle`).
- The session URL path (`<session_path>`) is set by the `session_url_path` preset input (default: `demo_execution`). If you changed it, update the URL accordingly.
