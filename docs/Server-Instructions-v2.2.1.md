# Da Vinci PAS Test Kit: Server Testing v2.2.1 Instructions

This document provides a step-by-step guide for running the Da Vinci PAS Test Kit to test a **server system (payer)**
against v2.2.1 of the IG. In this scenario, Inferno acts as the PAS client.

## Pre-execution Setup and Required Information

### Minimum Requirements

To run against the Da Vinci PAS Server v2.2.1 Test Suite, a PAS server implementation must at minimum
be able to receive PAS `$submit` requests from Inferno. Inferno must be able to reach the server's
FHIR base URL, and the server must accept requests at the `/Claim/$submit` endpoint under that base URL.

To perform a simple approval workflow, testers will need:

- The FHIR base URL for the PAS server under test.
- OAuth credentials, if the server requires authentication. The suite assumes any required authentication
  setup has been completed before the test run and uses the credentials supplied in the **OAuth Credentials**
  input when making requests to the server.
- A complete JSON-encoded PAS Request Bundle that will result in a prior authorization approval when
  sent to the server.

### Passing Requirements

Additional configuration and information is needed to demonstrate conformance to all tests in the suite.
In order to pass all tests in the suite, a PAS server implementation must

- Support the `$submit` and `$inquire` operations at the expected endpoints.
- Return the expected approval, denial, and pended outcomes for the tester-provided requests.
- Support creation of a REST-hook Subscription, including a handshake notification and a full-resource
  notification when a pended Claim is finalized.
- Receive the sequence of Claim Update `$submit` requests used by the Claim Updates group (add an 
  item, modify an item, cancel an item, cancel the request).

Because the business logic that determines decisions and the elements populated in responses varies between
implementers, testers must provide the request Bundles that Inferno will send to the server. To pass the
Must Support Elements group, those Bundles must collectively contain and elicit the required content. See the
[Server Testing Details](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Details)
documentation for technical implementation details and known limitations.

### Network Preparation

The pended workflow requires connectivity in both directions: Inferno must reach the server, and the server
must be able to send REST-hook notifications to the endpoint placed in the Subscription by Inferno. Ensure that
outbound network rules, proxy settings, and TLS configuration allow the server to reach that endpoint before
starting the Subscription Setup group.

## Quick Start

To execute a simple set of tests with minimal setup and input, perform an approval workflow with the
following steps:

1. Create a Da Vinci PAS Server Suite v2.2.1 session.
1. Select the "Successful Approval Workflow" group from the list at the left and click the "RUN TESTS"
   button in the upper right.
1. In the input dialog, provide the following values:
   - **FHIR Server Endpoint URL**: the base FHIR URL for the PAS server. Inferno appends
     `/Claim/$submit` when it sends the approval request.
   - **OAuth Credentials**: the credentials Inferno should use if authentication is required by the server.
   - **PAS Submit Request Payload for Approval Response**: a complete JSON-encoded PAS Request Bundle
     that will result in a claim approval from the server.
1. Click the "SUBMIT" button at the bottom right of the dialog.
1. Inferno validates the supplied request Bundle, sends it to `/Claim/$submit`, and validates the response.
1. Review the results including any errors or warnings found when checking the supplied request and the
   server response.

## Additional Testing Options

The following groups and inputs can be used to expand the process described in the
[Quick Start](#quick-start) section into a complete set of tests.

### Testing the Denial Workflow

Run the "Successful Denial Workflow" group in the same manner as the approval workflow. Provide a
**PAS Submit Request Payload for Denial Response** that is expected to result in a denial from the
server under test.

### Testing the Pended Workflow

To run the "Successful Pended Workflow" group, first run the "Subscription Setup" group. Provide a
**Pended Prior Authorization Subscription** resource in JSON format and a **Notification Access Token**.
Inferno validates the supplied Subscription and modifies its channel endpoint so that the server sends
notifications to Inferno. Inferno also ensures that the Subscription contains the supplied token as a
`Bearer` token in the `Authorization` header sent by the server to Inferno.

The Subscription Setup group sends the Subscription to the server and waits for a handshake notification.
After it completes, run the "Successful Pended Workflow" group with a **PAS Submit Request Payload for
Pended Response** that will result in a pended response from the server. After the server returns the
pended response, finalize the pended claim in the server's workflow so that it sends a full-resource event
notification to Inferno. Inferno automatically resumes when it receives the event notification, and then
it validates the notification content.

### Testing Claim Updates

The **Claim Updates** group sends four `$submit` requests in order:

1. An initial Claim submission.
1. An update that adds an item.
1. An update that modifies one item and cancels another.
1. An update that cancels the entire request.

Provide the four corresponding JSON-encoded Bundles in the inputs for this group. Construct them as a
single, stateful sequence in the server's test environment: each update must refer to the appropriate
previous Claim and the server must return a response for every step. Inferno validates each supplied
Bundle and response, then checks the item sequences returned across the sequence.

### Testing Must Support Elements

During the **Demonstrate Element Support** group, Inferno sends one or more additional `$submit` and
`$inquire` requests and then checks the requests and responses for the required must support elements.
Provide JSON-encoded Bundles in the **Additional $submit Request Payloads** and **Additional $inquire
Request Payloads** inputs. Each input may contain one Bundle or a JSON array of Bundles, for example
`[bundle_1, bundle_2]` where each value is a complete Bundle. The Must Support Elements tests use the
`$submit` and `$inquire` requests already sent during the test session in addition to the requests
supplied for this group.

### Testing Error Handling

The **Demonstrate Error Handling** group does not require a tester-provided error payload. Inferno sends
an intentionally empty Bundle to both `/Claim/$submit` and `/Claim/$inquire`. The server
is expected to return a non-2xx response containing an `OperationOutcome`.

## Interpreting Results

Due to [limitations of these tests](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Overview#test-scope-and-limitations),
passing this test suite in its entirety [does not prove conformance to the specification](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Overview#conformance-criteria--interpreting-results).

The request Bundle validation tests are marked as **Simulation Verifcation**. A skip in one of these tests
means Inferno deemed the supplied Bundle invalid. These validation errors should be considered when
interpreting the results of the subsequent tests that validate the server response.

## Inferno Client vs Server Execution

For a demonstration of the v2.2.1 server suite against Inferno's simulated PAS client rather than a
separate PAS implementation, see the instructions for
[running the Inferno client and server suites against each other](Running-Suites-Against-Each-Other).
