# Da Vinci PAS Test Kit Overview

This document provides a comprehensive overview of the Da Vinci Prior Authorization Support (PAS) Test Kit, its purpose, scope, testing methodologies, and limitations.

## Purpose

The Da Vinci PAS Test Kit is designed to validate the conformance of healthcare IT systems (both clients and servers) against [version 2.0.1 of the HL7 FHIR Da Vinci Prior Authorization Support (PAS) Implementation Guide (IG)](https://hl7.org/fhir/us/davinci-pas/STU2/). It helps implementers ensure their systems can correctly participate in electronic prior authorization workflows as defined by the PAS IG.

The test kit is built using the [Inferno Framework](https://inferno-framework.github.io/), an open-source platform for building FHIR-based test kits.

## Test Kit Structure and Methodology

The PAS Test Kit includes two main suites, targeting the different actors defined in the PAS IG:

*   **Server Test Suite**: For systems acting as payers. Inferno simulates a client, making a series of prior authorization requests to the server under test and validating its responses.
*   **Client Test Suite**: For systems acting as providers (e.g., EHRs). Inferno simulates a server, waiting for the client to initiate requests and then responding, while validating the client's requests and its ability to handle responses.

### General Testing Approach

In both client and server testing scenarios:
1.  **Workflow Simulation**: The tests guide the system under test (SUT) through key PAS workflows, such as:
    *   Submission of a prior authorization request.
    *   Receiving/Sending an approval.
    *   Receiving/Sending a denial.
    *   Handling a pended request and subsequent final decision (including subscription notifications for clients).
    *   Handling errors or inability to process requests (for servers).
2.  **Data Conformance**:
    *   **Must Support Elements**: The tests verify the SUT's ability to produce and/or consume all PAS-defined FHIR profiles and their "must support" elements. This applies to both prior authorization submissions and inquiries.
    *   **FHIR Validation**: All FHIR resources exchanged are validated against the PAS IG profiles using the official FHIR Java validator, with `tx.fhir.org` as the terminology server.
3.  **Authentication**:
    *   **Client Testing**: Inferno's simulated server supports SMART Backend Services, UDAP B2B client credentials flow (including dynamic registration), or an attestation-based approach for clients using other authentication methods.
    *   **Server Testing**: The PAS IG recommends server-server OAuth. The test kit currently requires a bearer token to be provided, which Inferno will use for all requests.

### Client Testing Specifics
*   Inferno acts as a PAS server.
*   The client under test initiates requests (e.g., `$submit`, `$inquire`, `Subscription` creation).
*   Inferno provides responses (either auto-generated based on IG examples or tester-provided) and validates the client's requests and its handling of these responses.
*   Workflows tested include approval, denial, and pended (with notifications).

### Server Testing Specifics
*   Inferno acts as a PAS client.
*   The tester provides the FHIR Bundle requests that Inferno will send to the server under test for various scenarios (approval, denial, pended, error).
*   Inferno makes requests to the server's `$submit` and `$inquire` endpoints.
*   Inferno validates the server's responses for conformance and appropriateness.
*   Subscription setup and notification handling for pended requests are also tested.

## Test Scope and Limitations

This test kit is a **DRAFT**. While it covers many core aspects of the PAS IG, there are known limitations and out-of-scope requirements.

### In-Scope (High-Level)

*   End-to-end prior authorization workflows (approval, denial, pended).
*   Ability to produce/receive (server) or send/handle (client) all PAS-defined profiles and their must-support elements for submissions and inquiries.
*   Basic subscription mechanics for pended request notifications.

### Key Out-of-Scope Requirements (Common to Client & Server unless specified)

*   **Private X12 Details**: Due to the proprietary nature of X12:
    *   Correct usage of X12-based terminology is not validated.
    *   Semantic meaning of X12 codes (e.g., specific approval/denial reasons) is not verified.
    *   Matching semantics for inquiry responses based on X12 content are not checked.
*   **Prior Authorization Update Workflows**: (`Claim/$update` operation).
*   **Requests for Additional Information (RFAI)**: Handled via the CDex IG.
*   **Attachments**: PDF, CDA, and JPG attachments as supporting information.
*   **US Core Profile Support**: For supporting information beyond PAS-defined profiles.
*   **Subscriptions (Advanced Details for v2.0.1)**: The v2.0.1 IG's subscription requirements are less mature. While basic mechanics are tested, finer details (like specific filter criteria stringency) are not deeply validated, anticipating changes in later IG versions.
*   **(Server) Inquiry Matching and Subsetting Logic**: Complex server-side logic for matching inquiry criteria or handling requests from non-submitting systems.
*   **(Server) Collection and Dissemination of Metrics**.
*   **(Client) Comprehensive Handling of All Response Variations**: Full validation of client's ability to handle every possible PAS-defined profile and must-support element in *responses* is not yet complete.
*   **(Client) Manual Review Aspects**: Requirements that necessitate manual review of the client system's UI/UX (e.g., clinician's ability to edit a request before submission).

### General Limitations

*   **Proprietary X12 Information**: The most significant limitation. Testers should attest to meeting X12-related requirements not verifiable by this tool.
*   **Draft Status**: The tests are evolving. Future versions may expand coverage or change validation logic. Feedback is encouraged.
*   **IG Issues**: Known issues in the PAS IG itself may cause false failures. These are typically documented in the test kit's issue tracker.

For a detailed, up-to-date list of specific in-scope/out-of-scope requirements and known issues, please refer to:
*   The "Testing Limitations" sections within the [Client Suite Description](../tree/main/lib/davinci_pas_test_kit/docs/client_suite_description_v201.md#testing-limitations) and [Server Suite Description](../tree/main/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations).
*   The [PAS Requirements Interpretation Spreadsheet](../tree/main/lib/davinci_pas_test_kit/docs/PAS%20Requirements%20Interpretation.xlsx).
*   The [test kit's GitHub Issues page](https://github.com/HL7/davinci-pas-test-kit/issues) (especially those tagged 'source ig issue').

## Test Prerequisites

*   **For Server Testing**:
    *   A running PAS-compliant FHIR server endpoint.
    *   An OAuth bearer token if the server requires authentication.
    *   Sample PAS request Bundles (for approval, denial, pended scenarios) that your server can process.
    *   A Subscription resource body (for pended workflow testing).
    *   A notification access token if your server requires it for sending notifications back to Inferno.
*   **For Client Testing**:
    *   A PAS-compliant client system capable of initiating `$submit`, `$inquire` operations and creating `Subscription` resources.
    *   Configuration for one of the supported authentication methods (SMART Backend Services, UDAP, or other via attestation).
    *   Optionally, pre-defined response Bundles if you don't want to use Inferno's auto-generated responses.

## Conformance Criteria & Interpreting Results

A test run is considered successful if all mandatory tests pass.
*   **Passing Tests**: Indicate that the SUT behaved as expected for that specific scenario or requirement.
*   **Failing Tests**: Indicate a deviation from the PAS IG requirements as interpreted by the test kit. Error messages and details provided by Inferno should help pinpoint the issue.
*   **Warnings/Informational Messages**: May highlight areas of concern, potential non-conformance, or provide context without necessarily failing a test.
*   **Skipped Tests**: Occur if prerequisites for a test were not met (e.g., an earlier, dependent test failed).

Given the "Known Limitations," especially regarding X12, passing all automated tests does **not** solely constitute full PAS IG conformance. Systems should also meet requirements verified through attestation or other means.

## Test Groups / Suites

The test kit organizes tests into logical groups, typically corresponding to:
*   **Authentication/Registration**: (e.g., Client Registration, Subscription Setup)
*   **Core Workflows**:
    *   Approval Workflow
    *   Denial Workflow
    *   Pended Workflow (often includes inquiry after notification)
*   **Error Handling**: (e.g., PAS Error Condition Tests for servers)
*   **Must Support Validation**: Tests dedicated to ensuring all required profiles and elements are supported in requests and responses.

Refer to the specific [Client Test Suite Description](../tree/main/lib/davinci_pas_test_kit/docs/client_suite_description_v201.md) and [Server Test Suite Description](../tree/main/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md) for more granular details on test groups.
