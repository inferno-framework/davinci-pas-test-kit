# Da Vinci PAS Test Kit: Client Testing v2.2.1 Instructions

This document provides a step-by-step guide for running the Da Vinci PAS Test Kit to test a **client system**
against v2.2.1 of the IG. In this scenario, Inferno acts as the PAS server.

## Pre-execution Setup and Required Information

### Minimum Requirements

To run against the Da Vinci PAS Client v2.2.1 Test Suite, a PAS client implementation must at minimum
be configured to make PAS $submit operation invocations against Inferno such that Inferno can
associate the requests with the session. The PAS Client v2.2.1 suite piggybacks on the [authentication
mechanism to identify the target session for a request](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#authentication-and-session-identification).
A standards-based authentication mechanism is not required to run the tests because the PAS Client v2.2.1
suite supports the use of dedicated endpoints without a formal authentication step for identification
of the session for a request.

### Passing Requirements

Additional configuration and information is needed to demonstrate conformance to all tested requirements.
In order to pass all tests in the suite, a PAS client implementation must
- Support the $inquire operation.
- Support the creation of Subscriptions and receipt of Notifications indicating that a final decision
  has been provided for a pended Claim.

Additionally, because the [mocked responses](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#generation-logic)
created by Inferno's simulation do not demonstrate all of the PAS must support elements defined
on the ClaimResponse profiles, testers will need to provide some custom responses that demonstrate all
of those elements. See the [Response and Notification Content](https://github.com/inferno-framework/davinci-crd-test-kit/wiki/Client-Details#response-and-notification-content)
section for details on specifying custom responses.

## Quick Start

To execute a simple set of tests with minimal setup and input, perform an approval workflow using
inferno-generated responses and dedicated session-specific endpoints with the following steps:

1. Create a Da Vinci PAS Client Suite v2.2.1 session using the "Other Authentication" option
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

## Additional Testing Options

The following groups and inputs can be used to expand the process described in the
[Quick Start](#quick-start) section into a complete set of tests.

### Testing the Denial, Claim Update, and Payer Mofidication Workflows

Groups "Denial Workflow", "Claim Updates" and "Payer Mofidication" can be run in the same manner as
described above. Testers may specify the responses for Inferno to return, but Inferno is also able
to generate [mocked responses](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#generation-logic)
for these workflows.

### Testing the Pended Workflow

To run the "Pended Workflow" group, first run the "Subscription Setup" group, during which the
client system will submit a Subscription so that Inferno knows how and where to send a
notification that a decision has been rendered on a pended prior authorization request.
Once that group has been run, proceed to execute the "Pended Workflow" group and follow the
instructions in the dialogs that appear. Inferno can
generate a [mocked pended response and a notification with the rendered decision](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#generation-logic).

### Testing Must Support Elements

During the "Must Support Elements" group, the client will submit multiple $submit and $inquire requests
to demonstrate all required must support elements, including on both the requests and response.
These tests can be run without providing custom responses, but because Inferno's mocked responses
will not populate all ClaimResponse must support elements, [custom responses](https://github.com/inferno-framework/davinci-crd-test-kit/wiki/Client-Details#response-and-notification-content)
will be needed to pass the group.

### Testing Error Responses

To run the "Error Handling" groups, the tester will need to provide the response bodies for Inferno to return
as Inferno is not currently able to generate these responses.

### Testing Authentication Interactions

When using a standard OAuth-based authentication approach, client systems will need to make requests
against Inferno to receive tokens and provide them on their PAS requests. Some of these details will
be verified as a part of the registration process. Others will require a set of tests to be run
after all other tests have been run.

On sessions using the SMART or UDAP options for authentication,
the Review Authentication Interactions group will be present as the last group. Testers will run this
group after all other tests and interactions have been performed and Inferno will verify that
the authentication details are conformant.

## Interpreting Results

Due to [limitations of these tests](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Overview#test-scope-and-limitations),
passing this test suite in its entirety [does not prove conformance to the specification](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Overview#conformance-criteria--interpreting-results).
Additionally, some of the capabilities tested by this suite are optional including many of the hooks
and response types, meaning that a conformant system will not necessarily be able to pass all tests
in the suite.

With those caveats, a passing execution of this suite would include passing all groups.

## Demonstration Execution

If you would like to try out the order-sign hook invocation tests against
[a public PAS reference client](https://crd-request-generator.davinci.hl7.org/),
you can do so using the following steps. Note that this reference implementation has
not been updated for the 2.2.1 version of the PAS IG so many failures are expected during this
execution. However, it can give you a sense for what executing the Inferno tests against a 
client system will look like.

TODO

## Inferno Client vs Server Execution

For another way to demonstrate test execution without an accompanying UI, see the instructions for
[running the Inferno client and server suites against each other](Running-Suites-Against-Each-Other).
