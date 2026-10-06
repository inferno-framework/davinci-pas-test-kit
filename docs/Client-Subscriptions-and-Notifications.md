# Simulated Subscriptions and Notifications

## Background

PAS requires that servers use Subscription notifications to alert clients when
a pended prioar authorization request has been updated. When simulating
a PAS server, Inferno will accept Subscriptions and use them to deliver
notifications to the client at appropriate times. This page describes
how Inferno's simulation of a Subscription server works, including
- How and when Inferno responds to Subscription creation requests.
- How and when Inferno generates Notifications.

## Subscription Creation Requests

In order to participate in a pended workflow, Inferno must know where to send
a notification to a client system. Subscription creation is expected to be a
step performed when connecting a client system to a new payer. Therefore, Inferno
asks testers to perform this step up-front as a part of the "Subscription Setup"
group. Testers must perform this step while Inferno is waiting during the
execution of this group. Otherwise, the pended scenario tests will not execute
and notifications will never be sent. Tester must perform this step for each
Inferno session they create as Inferno does not support sharing Subscription
details between sessions.

### Subscription Validation

Inferno performs minimal validation before accepting a Subscription to ensure
that it can send notifications based on it. To do so, Inferno requires:
- `channel.type` to be "rest-hook"
- `channel.endpoint` to be a valid "http" or "https" url
- that no [heartbeat](https://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition-backport-heartbeat-period.html),
  is requested as Inferno does not support sending these periodic notifications.

Additional conformance validation is performed as a part of the Inferno
tests, so acceptance does not imply that the Subscription will pass conformance
checks.

### Creation Response

#### Failure

Inferno will respond with an OperationOutcome describing the problem and continue
waiting for a successful Subscription creation request in the following cases:
- No session found: Returned when the submission endpoint URL or bearer token
  do not identify an actively waiting PAS client session.
- Expired Token: Returned when the bearer token provided with the request has
  expired.
- Invalid or unsupported Subscription: Returned when the requested Subscription
  is not valid JSON or does not meet Inferno's [acceptance requirements](#subscription-validation).
- A valid Subscription has already been created for this session: Returned when
  Inferno has already received a successful Subscription creation request for this
  session as Inferno does not support sending multiple notifications. If the
  original Subscription does not work, you can re-run the Subscription Creation
  group (requests from the prior run will not be considered).

#### Success

When the Subscription is accepted, Inferno will return a 201 CREATED status 
with the requested Subscription echoed in the body with the following changes:
- Assign a fresh `id` value
- Update the `status` to be "requested"
- If the provided `channel.payload` value is not either "application/fhir+json" or
  "application/json", update it to be "application/fhir+json" (Inferno only supports
  sending notifications in the JSON format)

It will subsequently trigger a job to send a handshake notification.

### Handshake Notification

Inferno will send a basic handshake notification using the [Parameters format](https://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition-backport-subscription-status-r4.html).
Unless the request timesout or otherwise Inferno doesn't receive a respons, the tests
will continue automatically regardless of the details of the client's response to
the handshake.

Additional conformance validation is performed as a part of the Inferno
tests, so acceptance of the handshake response does not imply that the
response will pass conformance checks.

## Subscription Notifications

Inferno will send a notification during the Pended Response scenario group. After
receiving a `$submit` request during this group, Inferno will return a pended
response ([mocked](Controlling-Simulated-Responses#mocked-responses)
or [specified by the tester](Controlling-Simulated-Responses#tester-directed-custom-responses)).
Depending on which suite is in use, the notification will be sent either
- Within 5-10 seconds of the pended response for the PAS Client v2.0.1 suite, or
- After attesting to the display of the pended status for the PAS Client v2.2.1 suite.

In either case, Inferno will either [mock a notification based on the `$submit` request](Controlling-Simulated-Responses#notification-bundle) or return a [tester-provided
notification with some updates](Controlling-Simulated-Responses#inferno-modifications-of-tester-provided-responses-and-notifications).
