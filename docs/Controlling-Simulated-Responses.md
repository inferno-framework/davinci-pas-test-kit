# Controlling Responses from Inferno's Simulated PAS Server

During the PAS client tests, testers must demonstrate that their PAS client
can handle a wide variety of conformant PAS responses and notifications,
including a variety of scenarios (e.g., different decisions) and coverage
of must support elements within response profiles. Inferno allows testers
to provide the responses for Inferno to return because:
1. Requiring systems to handle specific responses could require additional setup
   (e.g., configuration of certain order codes) that could inadvertently place
   requirements on systems beyond what is required by the PAS specification.
2. Inferno does not have the expertise or capability to produce sensical responses
   for all systems that also cover all must support elements.
  
Additionally, because the specification of responses for Inferno to use can be complex,
Inferno can mock simple responses without tester input. While these responses
can be useful for a basic demonstration, to fully pass the tests testers will need
to provide some responses for Inferno to return to their PAS client.

However they are determined, Inferno's responses must appear as if sent by a generic
server conformant to the PAS specification and not going beyond it. Each response:
- Must be conformant: because only handling of conformant responses demonstrates support
  for PAS interop
- Cannot contain data that goes beyond the PAS standard: this prevents the PAS client
  from relying on custom data. Inferno enforces this requirement by failing when
  a custom extension, i.e., one not defined within PAS or the IGs it depends on, is found
  within a response returned by Inferno. PAS client requests are allowed to have custom extensions,
  so resources echoed back from the request in Inferno responses (e.g., the Patient resource)
  may keep the extensions they had in the request, as long as they are unchanged. See
  [Validation](Client-Details#validation) for details on how echoed resources are identified
  and the messages reported. Testers are welcome to provide feedback on the current behavior
  via GitHub issues.

## Mocked Responses

When generating responses and notifications, Inferno uses the following logic. Responses
generated in this way conform to the requirements of the PAS specification, but may not
make clinical sense when received by a real PAS client.

### `$submit` and `$inquire` responses

These responses are created mostly from the incoming request. Specific details include:

- The Patient, insurer Organization, and requestor entity instances are pulled into the response
  Bundle and referenced in the `patient`, `insurer`, and `requestor` elements respectively.
  Note that these are found by following references in the submitted Claim instance. If relative
  references are used in the Claim, the Claim entry `fullUrl` needs to be an absolute reference
  and not a UUID, else the entries won't get pulled in correctly. These entries are echoed as
  they appear in the request, including any extensions.
- In the ClaimResponse, the `identifier`, `type`, `status`, and `use` elements are pulled
  in from the Claim in the request. Extensions not published by HL7 (i.e., with urls not
  starting with `http://hl7.org/fhir/`) are removed from the elements copied from the Claim,
  including the `patient`, `insurer`, and `requestor` references and, in the Payer Modification
  scenario, `addItem.productOrService`, since Inferno, acting as the payer, doesn't send custom
  extensions.
- The `Bundle.timestamp` and `ClaimResponse.created` timestamps are populated using the current time.
- The `ClaimResponse.outcome` is set to `complete`, except for v2.0.1 pended responses, which use `queued`.
- For each `item` entry in the request Claim, a `ClaimResponse.item` entry is created with the
  `itemSequence` value copied over, `itemPreAuthIssueDate` and `itemPreAuthPeriod` extensions 
  added using the current date and a month starting on the current date respectively,
  and an adjudication entry with a `category` of `submitted` that contains the `reviewAction` extension with a
  `reviewActionCode` that matches the current scenario: `A1` ("Certified in total") for approval,
  `A3` ("Not Certified") for denial, `A4` ("Pending") for pending, and `A6` ("Modified") for
  modified. For the claim updates scenario, `A1` ("Certified in total") will be used.
- In the Payer Modification scenario, a `ClaimResponse.addItem` entry is added for each
  `item` entry in the Claim representing the modification. The `reviewActionCode` for these
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
- The subscription's `events-since-subscription-start` and the event's `event-number` count the event
  notifications Inferno has sent during the test session.
- When generating a `full-resource` notification, Inferno will include `additional-context`
  references for each entry in the `$submit` response Bundle other than the ClaimResponse
  (which is already in the `focus`). Then it will include Notification Bundle entries for
  each instance in the `$submit` response Bundle, including the ClaimResponse, with `reviewActionCode`
  extensions updated to indicate approval using code `A1` ("Certified in total").

## Tester-directed Custom Responses

All PAS tests include the option for Inferno to return tester-provided responses.

### Response Selection

In most cases, Inferno will wait for a single $submit request and automatically continue the tests
after it has been received and responded to. In those cases, testers have the option to specify
a single response which will always be used.

In the case of the must support group, testers can send multiple $submit and $inquire
requests before explicitly clicking a link telling Inferno that all desired requests have
been made. Inferno allows a list of responses with criteria indicating when to use them.
In the v2.2.1 suite, a list of [notifications](#must-support-notifications) can be provided the same way.

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

The `bundle` key holds the response resource. This is normally a Bundle, but it may also be a
Parameters resource wrapping the response Bundles, such as for v2.2.1 `$inquire` responses. When
a Bundle is provided for a v2.2.1 `$inquire` response, Inferno wraps it in a Parameters resource.
An entry may also be a bare Bundle or Parameters resource with no criteria.

#### Response Option Evaluation

For each request, Inferno will respond with the response resource of the first entry whose criteria
are all met. An entry with no criteria (including a bare Bundle or Parameters) matches any request, and an entry with multiple
criteria must meet all of them. If no entry matches, or none are provided, Inferno will generate a
default response. Supported fields within the "criteria" object include:

- `requestRange`: a string of comma-separated request numbers or ranges, e.g., "1-2,4". Requests
  are numbered starting from 1 and counting only requests against the target operation ($submit
  or $inquire) within a single "User Action Required" dialog. A request meets the criteria when its
  number is one of the listed numbers or falls within one of the listed ranges.
- `fhirpath`: a FHIRPath expression evaluated against the incoming request Bundle. A request
  meets this criterion when the expression evaluated against the request body returns a single
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

#### Must Support Notifications

In the v2.2.1 suite, when Inferno returns a pended response (`reviewActionCode` of `A4`) during the
*Demonstrate Must Support Coverage* group, it then notifies the PAS client of the final decision.
Inferno's mocked responses in this group are never pended, so this requires a pended response in the
**Must Support $submit Response Bundles** input.

The notification is selected from the **Must Support Notification Bundles** input, which uses the
[response option format](#response-option-format) with a notification Bundle in place of the response,
with criteria [evaluated](#response-option-evaluation) against the `$submit` request. If no entry matches,
Inferno [mocks](#notification-bundle) one. Notifications are sent up to about 11 seconds after the
response, and only while the test is waiting, so wait at least 15 seconds after the last pended response
before continuing.

### Response Instantiation

Before returning a selected response, Inferno will update it with dynamic content,
including expression tokens specified by the tester and request-time details
that they may not have known ahead of time.

#### Expression Tokens

Expression tokens for dynamic content are indicated by a FHIRPath expression surrounded by double curly braces
(`{{<FHIRPath expression>}}`) within JSON strings. The indicated FHIRPath
expression will be evaluated against the request and the result used to replace the token.

These can be used to make sure that details in the response reflect those in
the request. For example, `entry.resource.ofType(Claim).patient.reference` would return the reference to the
Patient resource the Claim was submitted for, which could be used to make sure that the ClaimResponse in the
response references the same Patient record.

How the result is used depends on where the token appears:
- **Whole value**: when a JSON string contains only the token (e.g., `"type": "{{entry.resource.ofType(Claim).type}}"`),
  the string is replaced by the results themselves, which can be strings, numbers, booleans, data types, or
  whole resources and Bundle entries. Within a JSON array, each result is inserted in place of the token, so
  `"entry": [..., "{{entry.where(resource is Patient)}}"]` copies every Patient entry from the request. For
  other elements, a single result becomes the element's value, several results become an array, and no results
  remove the element. Extensions not published by HL7 are removed from copied data types, as in
  [mocked responses](#submit-and-inquire-responses), while resources and Bundle entries are copied as they are.
  Because results keep their type, a number copied into a text element must be converted, e.g., with
  `.select(toString())`, and several results can be combined into one text value with `.join(',')`.
- **Within text**: when the token is part of a longer string (e.g., `"text": "Response to {{...}}"`),
  results that are primitive values are joined with commas and inserted into the text, and other results are
  ignored.

Notes:
- Inferno supports the raw `today()` function alone as well as with addition
  and subtraction of days, e.g., `{{today()}}`, `{{today() - 7 days}}`, and
  `{{today() + 365 days}}`.
- While the syntax follows CDS Hooks prefetch tokens, Inferno allows additional FHIRPath functions
  beyond the [limited set allowed by CDS Hooks](https://cds-hooks.hl7.org/2026Jan/en/#prefetch-tokens-containing-simpler-fhirpath). See 
  the [FHIRPath Evaluation Limitations](#fhirpath-evaluation-limitations) section for details.
- `resolve()` is not supported, so to find the Bundle entry for a reference in the Claim, compare entry
  `fullUrl` values to it, using `%resource` to refer to the request Bundle, e.g.,
  `entry.where(fullUrl.endsWith('/' + %resource.entry.resource.ofType(Claim).patient.reference))`.

#### Repeated Content

To include content once for each result of a FHIRPath expression, such as a `ClaimResponse.item` for
each `Claim.item`, use an object holding the expression under `$forEach` and the content to repeat under
`template`:

```
"item": [
  {
    "$forEach": "entry.resource.ofType(Claim).item",
    "template": {
      "itemSequence": "{{%current.sequence}}",
      "adjudication": [ ... ]
    }
  }
]
```

Within the template, `%current` in an expression token refers to the result the copy is for. Each copy is
inserted into the array in place of the object, and no results remove it. `$forEach` objects can be nested,
in which case `%current` refers to the result of the innermost one.

#### Example: Mocked Responses as Templates

The [mocked `$submit` and `$inquire` responses](#submit-and-inquire-responses) can be written as tester-provided
responses using expression tokens. The Da Vinci PAS Test Kit's tests check that the templates in its
[response templates folder](https://github.com/inferno-framework/davinci-pas-test-kit/tree/main/spec/fixtures/response_templates)
produce the same responses as Inferno's mocks, which can serve as starting points. For example, the
approval `$submit` response for v2.0.1 has the following structure (static content left out):

```
{
  "resourceType": "Bundle",
  "type": "collection",
  "timestamp": "2025-01-01T00:00:00Z",
  "entry": [
    {
      "fullUrl": "urn:uuid:5f0c6a8e-1d2b-4c7a-9e3f-8b4d2a6c1e70",
      "resource": {
        "resourceType": "ClaimResponse",
        "id": "5f0c6a8e-1d2b-4c7a-9e3f-8b4d2a6c1e70",
        "identifier": ["{{Bundle.entry.resource.ofType(Claim).identifier}}"],
        "status": "{{Bundle.entry.resource.ofType(Claim).status}}",
        "type": "{{Bundle.entry.resource.ofType(Claim).type}}",
        "use": "{{Bundle.entry.resource.ofType(Claim).use}}",
        "patient": {
          "reference": "{{Bundle.entry.where(fullUrl = %resource.entry.resource.ofType(Claim).patient.reference or fullUrl.endsWith('/' + %resource.entry.resource.ofType(Claim).patient.reference)).fullUrl}}"
        },
        "created": "2025-01-01T00:00:00Z",
        "request": { "reference": "{{Bundle.entry.where(resource is Claim).fullUrl}}" },
        "outcome": "complete",
        "preAuthPeriod": { "start": "{{today()}}", "end": "{{today() + 1 month}}" },
        "item": [
          {
            "$forEach": "Bundle.entry.resource.ofType(Claim).item",
            "template": {
              "extension": [ ... itemPreAuthIssueDate and itemPreAuthPeriod using today() ... ],
              "itemSequence": "{{%current.sequence}}",
              "adjudication": [ ... reviewActionCode A1 ... ]
            }
          }
        ],
        ... insurer and requestor follow the same pattern as patient ...
      }
    },
    "{{Bundle.entry.where(fullUrl = %resource.entry.resource.ofType(Claim).patient.reference or fullUrl.endsWith('/' + %resource.entry.resource.ofType(Claim).patient.reference))}}",
    ... the insurer and requestor entries follow the same pattern ...
  ]
}
```

These templates copy the patient, insurer, and requestor entries as they are in the request. Unlike the mock,
they don't include further entries that those entries reference, don't update references within the copied
entries to use `fullUrl` values, and include an entry referenced by more than one of the patient, insurer,
and requestor once for each reference. Add tokens for any other entries the response needs.

#### Inferno Modifications of Tester-provided Responses and Notifications

Following token instantiation, responses provided by testers will be modified by Inferno
to populate and update details that testers won't know ahead of time. These modifications
fall into three categories:
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
- **Event Counts**: `events-since-subscription-start` and the `event-number` will be updated as for
  [mocked notifications](#notification-bundle).

If the tester provides an input that is malformed in some way such that Inferno cannot get the details
that it needs to make the modifications, then the raw input will be used.

Note that extensions on primitive elements (e.g., `_birthDate` in JSON) are not currently supported
and will be removed from tester-provided responses before they are sent.

### Response and Notification Correspondence Requirements

Beyond the minor modifications described above, Inferno does not modify provided resources to ensure that
they are consistent with each other or the time they are executed. For example, in the pended
scenario, it is up to the tester to ensure that if they provide responses for the `$submit` operation and
for the `$inquire` operation (v2.0.1) or notification body (v2.2.1) that both messages share whatever details,
such as identifiers, needed to connect them together and drive the workflow in the PAS client. Timestamps
not associated with messaging time such as when a prior authorization response is valid are also not modified
by Inferno. Unlike details that Inferno modifies as described above, testers should have control over and/or
knowledge of the necessary details and values to construct consistent and working messages for Inferno to use.

In the v2.2.1 must support group, responses and notifications are selected separately, so testers must
make sure their criteria pair them correctly. Inferno warns when a notification's ClaimResponse shares
neither an `id` nor an `identifier` with the pended response's ClaimResponse.

### FHIRPath Evaluation Limitations

The configurability of responses relies heavily on FHIRPath and is therefore limited by the
FHIRPath language and the parts of it that are implemented by Inferno's FHIRPath evaluation
engine. Inferno currently uses the FHIRPath engine built into the official HL7 FHIR validator
to evaluate FHIRPath expressions on FHIR resources.

Inferno's use of the HL7 FHIR Validator's FHIRPath engine comes with some restrictions.
- The engine is not configured to resolve profiles or value sets. It has the base FHIR R4
  definitions loaded, so functions like `ofType` will work, but types defined in IGs or elsewhere
  cannot be used.
- The FHIRPath engine may not implement the entire [FHIRPath specification](https://hl7.org/fhirpath/N1/index.html),
  for example the `resolve()` function is not supported.

The Inferno team is open to adding support for additional FHIRPath functions. Please submit a
[GitHub issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues) with details
of your use case and the additional features that you believe are necessary.
