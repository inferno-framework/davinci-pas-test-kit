# Controlling Responses from Inferno's Simulated PAS Server

During the PAS client tests, testers must demonstrate that their system
can handle a wide variety of conformant PAS responses and notifications,
including a variety of scenarios (e.g., different decisions) and coverage
of must support elements within response profiles. Inferno allows testers
to provide the responses for Inferno to make because:
1. Requiring systems to handle specific responses could require additional setup
   (e.g., configuration of certain order codes) that could inadvertantly place
   requirements on systems beyond what is required by the PAS specification.
2. Inferno does not have the expertise or capability to produce sensical responses
   to all systems that also cover all must support elements
  
Additionally, because the specification of responses for Inferno to use can be complex,
Inferno can mock simple responses without tester input. While these response
can be useful for a basic demonstration, to fully pass the tests testers will need
to provide some responses for Inferno to return to their system.

However they are determined, Inferno's responses must appear as if sent by a generic
server conformant to the PAS specification and not going beyond it. Each response:
- Must be conformant: because only handling of conformant responses demonstrate support
  for PAS interop
- Cannot contain data that goes beyond the PAS standard: this prevents the client
  system from relying on custom data. Inferno enforces this requirement by failing when
  a custom extension not defined within PAS is found within a response returned by Inferno.
  While client requests are typically allowed to have custom extensions, custom extensions on
  portions of the request that are echoed back in Inferno responses (e.g., the Patient resource),
  will cause failures on the responses. This may be relaxed in the future and testers are
  welcome to provide feedback on the current behavior via github issues.

## Mocked Responses

When generating responses and notifications, Inferno uses the following logic. These conform to the
requirements of the PAS specification, but may not make sense in an actual workflow.

### `$submit` and `$inquire` responses

These responses are created mostly from the incoming request. Specific details include:

- The Patient, insurer Organization, and requestor entity instances are pulled into the response
  Bundle and referenced in the `patient`, `insurer`, and `requestor` elements respectively.
  Note that get found by following references found in the submitted Claim instance. If relative
  references are used in the Claim, the Claim entry `fullUrl` needs to be a absolute reference
  and not a UUID, else the entries won't get pulled in correctly.
- In the ClaimResponse, the `identifier`, `type`, `status`, and `use` elements are pulled
  in from the Claim in the request.
- The `Bundle.timestamp` and `ClaimResponse.created` timestamps are populated using the current time.
- The `ClaimResponse.outcome` is hardcoded to `complete`.
- For each `item` entry in the request Claim, a `ClaimResponse.item` entry is created with the
  `itemSequence` value copied over, `itemPreAuthIssueDate` and `itemPreAuthPeriod` extensions 
  added using the current date and a month starting on the current date respectively,
  and an adjudication entry with a `category` of `submitted` that contains the `reviewAction` extension with a
  `reviewActionCode` that matches the current workflow: `A1` ("Certified in total") for approval,
  `A3` ("Not Certified") for denial, `A4` ("Pending") for pending, and `A6` ("Modified") for
  modified. For the claim updates workflow, `A1` ("Certified in total") will be used.
- In the Payer Modification scenario, a `ClaimResponse.addItem` entry is added for each
  `item` entry in the Claim respresenting the modification. The `reviewActionCode` for these
  entries will be `A1` ("Certified in total"), but all other elements will be the same
  making it a vacuous update.

### Notification Bundle

Inferno supports mocking both `id-only` and `full-resource` notifications. The following details are relevant:

- Inferno pulls in details from the Subscription created for the test session to use in
  creating the Notification, including the `topic` and the `subscription` reference.
- Inferno hardcodes the `status` as `active` and the `type` as `event-notification`.
- Inferno will always include a single `notification-event` entry with a `timestamp` of the current
  time and with a `focus` that points to the ClaimResponse returned on the `$submit`.
  If it cannot find the ClaimResponse reference from the `$submit` response returned
  by Inferno, it will generate a random UUID (which isn't likely to work correctly when received).
- The subscription's `events-since-subscription-start` and the event's `event-number` will always
  be 1 as Inferno is not able to track notifications across multiple sessions or runs.
- When generating a `full-resource` notification, Inferno will include `additional-context`
  references for each entry in the `$submit` response Bundle other than the ClaimResponse
  (which is already in the `focus`). Then it will include Notification Bundle entries for
  each instance in the `$submit` response Bundle, including the ClaimResponse, with `reviewActionCode`
  extensions updated to indicate approval using code `A1` ("Certified in total") for approval.

## Tester-directed Custom Responses

All PAS tests include the option for Inferno to return tester-provide responses.

### Response Selection

In most cases, Inferno will wait for a single $submit request and automatically continue the tests
after it has been received and responded to. In those cases, testers have the option to specify
a single response which will always be used.

In the case of the must support group, testers can send multiple $submit and $inquire
requests before explicitly clicking a link telling Inferno that all desired requests have
been made. Inferno allows a list of responses with criteria indicating when to use them.

#### Response Option Format

Each entry uses the following format:

```
{
  "criteria": {
    "requestRange": "optional list of request numbers or ranges, e.g., 1-2,4.",
    "fhirpath": "optional fhirpath expression executed against the request Bundle"
  },
  "bundle": {
    "resourceType": "Bundle",
    ...
  }
}

```

#### Response Option Evaluation

For each request, Inferno will respond with the Bundle of the first entry whose criteria are all met.
An entry with no criteria (including a bare Bundle) matches any request, and an entry with multiple
criteria must meet all of them. If no entry matches, or none are provided, Inferno will generate a
default response. Supported fields within the "criteria" object include:

- `requestRange`: a string of comma-separated request numbers or ranges, e.g., "1-2,4". Requests
  are numbered starting from 1 and counting only requests against the target operation ($submit
  or $inquire) within a single "User Action Required". A request meets the criteria when its
  number is one of the listed numbers or falls within one of the listed ranges.
- `fhirpath`: a FHIRPath expression evaluated against the incoming request Bundle. A request
  meets this criteria when the expression evaluated against the request body returns a single
  truthy value.

For example, the following list will return a denial response for a specific patient,
a pended response for the third request and an approval response for all others:

#### Response Options Example

```
[
  {
    "criteria": {
      "fhirpath": "entry.resource.ofType(Claim).patient.reference='Patient/123'"
    },
    "bundle": {
      "resourceType": "Bundle",
      ... Denial Response ...
    }
  },
  {
    "criteria": {
      "requestRange": "3"
    },
    "bundle": {
      "resourceType": "Bundle",
      ... Pended Response ...
    }
  },
  {
    "bundle": {
      "resourceType": "Bundle",
      ... Approval Response ...
    }
  }
]
```

### Response Instantiation

Before returning a selected response, Inferno will updated it with dynamic content,
including expression tokens specified by the tester and request-time details
that they may not have known ahead of time.

#### Expression Tokens

Expression tokens for dynamic content indicated by a FHIRPath expression surrounded by double curly braces
(`{{<FHIRPath expression}}`) within FHIR elements. The indicated FHIRPath
expression will be evaluated against the request and the result used to replace the token.

These can be used to make sure that details in the response reflect those in
the request. For example, `entry.resource.ofType(Claim).patient.reference` would return the rerefernce to the
Patient resource the Claim was submitted for, which could be used to make sure that the ClaimResponse in the
response references the same Patient record.

Notes:
- Entries within the returned collection that are not data types (lists or objects) will be ignored.
- If multiple entries (not including ignored and nil entries) are returned, then the results will
  be turned into a comma-delimited list for use in replacing the token.
- Inferno supports the raw `today()` function alone as well as with addition
  and subtraction of days, e.g., `{{today()}}`, `{{today() - 7 days}}`, and
  `{{today() + 365 days}}`.
- While the syntax follows CDS Hooks prefetch tokens, Inferno allows additional FHIRPath functions
  beyond the [limited set allowed by CDS Hooks](https://cds-hooks.hl7.org/2026Jan/en/#prefetch-tokens-containing-simpler-fhirpath). See 
  the [FHIRPath Evaluation Limitations](#fhirpath-evaluation-limitations) section for details.

Note that at this time, only string data can be added with expression tokens.

#### Inferno Modifications of Tester-provided Responses and Notifications

Following token instantiation, requests provided by testers will be modified by Inferno
to populate and update details that testers won't know ahead of time. These modifications
fall into two categories:
- **Timestamps**: creation timestamps, such as those on Bundles, ClaimResponses, and event notifications,
  will be updated or populated by Inferno so that they are in sync with the time the message is sent.
- **Resource Ids**: some resource ids will not be known ahead of time and will be added or updated
  by Inferno including
  - *Claim Id*: if the tester provides a `$submit` or `$inquire` response with `ClaimResponse.request`
    populated, then Inferno will update it with the fullUrl of the Claim provided in the request.
    This avoids the need for testers to know the Claim Id ahead of time which may be difficult for
    some systems.
  - *ClaimResponse Id*: if the tester provides a Notification but has Inferno generate the `$submit`
    response, then Inferno will update the focus to use the ClaimResponse id that it generates.

If the tester provides an input that is malformed in some way such that Inferno cannot get the details
that it needs to make the modifications, then the raw input will be used.

### Response and Notification Correspondence Requirements

Beyond the minor modifications described above, Inferno does not modify provided resources to ensure that
they are consistent with each other or the time they are executed. For example, in the pended
workflow, it is up to the tester to ensure that if they provide responses for the `$submit` operation and
for the `$inquire` operation (v2.0.1) or notification body (v2.2.1) that both messages share whatever details,
such as identifiers, needed to connect them together and drive the workflow in their system. Timestamps
not associated with messaging time such as when a prior authorization response is valid are also not modified
by Inferno. Unlike details that Inferno modifies as described above, testers should have control over and/or
knowledge of the necessary details and values to construct consistent and working messages for Inferno to use.

### FHIRPath Evaluation Limitations

The configurability of responses relies heavily on FHIRPath and is therefore limited by the
FHIRPath language and the parts of it that are implemented by Inferno's FHIRPath evaluation
engine. Inferno currently uses the FHIRPath engine built into the official HL7 FHIR validator
to evaluate FHIRPath expressions on FHIR resources.

Inferno's use of the HL7 FHIR Validator's FHIRPath engine comes with some restrictions.
- The engine is not configured to resolve profiles or value sets. It has the base FHIR R4
  definions loaded, so functions like `ofType` will work, but types defined in IGs or elsewhere
  cannot be used.
- The FHIRPath engine may not implement the entire [FHIRPath specication](https://hl7.org/fhirpath/N1/index.html),
  for example the `resolve()` function is not supported.

The Inferno team is open to adding support for additional FHIRPath functions. Please submit a
[GitHub issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues) with details
of your use case and the additional features that you believe are necessary.
