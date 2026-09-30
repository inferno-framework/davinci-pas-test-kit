# Client Suite Implementation Details

The Da Vinci PAS Test Kit Client Suite validates the conformance of client
systems to the HL7® FHIR® Da Vinci Prior Authorization Support Implementation Guide,
including versions
- [2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/), and
- [2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/).

These tests are a **DRAFT** intended to allow PAS client implementers to perform
preliminary checks of their clients against PAS IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-pas-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Technical Implementation

In these test suites, Inferno simulates a PAS server for the client system to
interact with. The client will be expected to initiate requests to the server
and demonstrate its ability to react to the returned responses. Over the course
of these interactions, Inferno will seek to observe conformant handling of PAS
requirements, including:
- The ability of the client to initiate a prior authorization submission and react to
    - The approval of the request
    - The denial of the request
    - The pending of the request and a subsequent notification that a final decision was made
    - additional scenarios such as updates, payer modifications, and errors (v2.2.1 only)
- The ability of the client to provide data covering the full scope of required by PAS, including
    - The ability to send prior auth requests and inquiries with all PAS profiles and all must
      support elements on those profiles
    - The ability to handle responses that contain all PAS profiles and all must support elements
      on those profiles

All requests and responses will be checked for conformance to the PAS
IG requirements individually and used in aggregate to determine whether
required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

### Responses

Inferno contains basic logic to generate approval, denial, and pended responses, along with a
notification that a final decision was made, as a part of the above scenarios.
These responses are based on examples available in the PAS Implementation Guide
and are conformant, but may not meet the needs of actual implementations. Thus,
testers may provide Inferno with specific responses for Inferno to echo. If responses
are provided, Inferno will check them for conformance to ensure that they demonstrate
a fully conformant exchange. See the **[Controlling Client Suite Simulated Responses](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses)**
section for details on how Inferno creates responses.

Note that Inferno currently does not accept `$inquire` requests during most PAS tests. Only
the Must Support tests and the v2.0.1 Pended Response tests will respond to `$inquire`
operation request with a successful response. This restriction may be relaxed in the
future. Implementers are welcome to submit a [GitHub Issues](https://github.com/inferno-framework/davinci-pas-test-kit/issues)
ticket in this repository if supporting `$inquire` requests at more points within the client
suite is needed for their client system to use these tests.

### Authentication and Session Identification

The Privacy and Security section of the PAS Implementation Guide
([v2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/privacy.html),
[v2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/privacy.html)) states that payers
must "require that the provider system authenticates"
itself when making PAS requests against the payer system. However, the specific method of authentication
is left to the Da Vinci HRex IG, which [provides recommendations and potential 
approaches](https://hl7.org/fhir/us/davinci-hrex/STU1/security.html#exchange-security) for
authentication, but does not require a specific one to be used.

Inferno's use of authentication on incoming requests is different from that of system its tests
because its primary goal is to identify the session to associate a request with and to verify correct behavior,
not to protect information (PHI must never be sent to publish Inferno endpoints). Thus, Inferno's
simulation will in some cases allow requests to proceed without a successful authentication step,
such as when using a dedicated session endpoint or receiving a JWT with an invalid signature
as a bearer token. In both cases the tests separately verify that authentication was successful
and only pass when the implementation is secure.

Inferno's simulated payer server includes a simulation of two standard authentication approaches:
- SMART Backend Services
- UDAP B2B client credentials flow, including dynamic registration

Client systems can register with the authorization server and request tokens for use
when making PAS requests. In this case, Inferno will verify that the client's interactions with
the simulated authorization server are conformant and that the provided tokens are used.

If the client system does not support either of these standards-based methods of authentication, the tester
may instead attest to other authentication capabilities. In this case, the client system will not
authenticate and will identify itself to Inferno by by sending requests to dedicated PAS endpoints
created by Inferno for use during the testing session. To reduce configuration burden, the dedicated
endpoints can be reused in subsequent sessions.

### Must Support Tests

PAS Clients are required to demonstrate support for some elements which appear only
under certain conditions. See the **[Client Must Support](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support)**
section for details on what Inferno checks for and the underlying requirements
that drive those tests.

## Auth Configuration Details

When running these tests there are 3 options for authentication, which also allows 
Inferno to identify which session the requests are for. The choice is made when the
session is created with the selected Client Security Type option, which determines
what details the tester needs to provide during the Client Registration tests:

- **SMART Backend Services**: the system under test will manually register
  with Inferno and request access tokens for use when accessing FHIR endpoints
  as per the SMART Backend Services specification. It requires the
  **SMART JSON Web Key Set (JWKS)** input to be populated with either a URL that resolves
  to a JWKS or a raw JWKS in JSON format. Additionally, testers may provide
  a **Client Id** if they want their client assigned a specific one.
- **UDAP B2B Client Credentials**: the system under test will dynamically register
  with Inferno and request access tokens used to access FHIR endpoints
  as per the UDAP specification. It requires the **UDAP Client URI** input
  to be populated with the URI that the client system will use when dynamically
  registering with Inferno. This will be used to generate a client id (each
  unique UDAP Client URI will always get the same client id).
- **Other Authentication**: Inferno will create a dedicated set of FHIR endpoints for this session
  so that the system under test does not need to get access tokens or provide
  them when interacting with Inferno during these tests. Since PAS requires
  authentication of client systems, testers will be asked to attest that their
  system supports another form of authentication, such as mutual authentication TLS.
  This approach uses the **Session-specific URL path extension** input to create a
  session-specific URL. This input can be provided for re-use across sessions, or
  left blank to have Inferno generate a value.

## Testing Limitations

### Private X12 details

HIPAA [requires](https://hl7.org/fhir/us/davinci-pas/STU2/regulations.html) electronic prior authorization
processing to use the X12 278 standard. While recent CMS rule-making suggests that [this requirement
will not be enforced in the future](https://www.cms.gov/newsroom/fact-sheets/cms-interoperability-and-prior-authorization-final-rule-cms-0057-f),
the current PAS IG relies heavily on X12.  As the IG authors note at the
top of the IG home page ([v2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/index.html),
 [v2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/index.html)):

> Note that this implementation guide is intended to support mapping between FHIR and X12 transactions. To respect
> X12 intellectual property, all mapping and X12-specific terminology information will be solely published by X12
> and made available in accordance with X12 rules - which may require membership and/or payment. Please see this
> [Da Vinci External Reference page](https://confluence.hl7.org/display/DVP/Da+Vinci+Reference+to+External+Standards+and+Terminologies)
> for details on how to get this mapping.
>
> There are many situationally required fields that are specified in the X12 TRN03 guide that do not have guidance
> in this Implementation Guide. Implementers need to consult the X12 PAS guides to know the requirements for these
> fields.
>
> Several of the profiles will require use of terminologies that are part of X12 which we anticipate being made
> publicly available. At such time as this occurs, the implementation guide will be updated to bind to these as
> external terminologies.

The implications of this reliance on proprietary information that is not publicly available means that this test
kit:

- *Cannot verify the correct usage of X12-based terminology*: terminology requirements for all elements bound to X12
value sets will not be validated.
- *Cannot verify matching semantics on inquiries*: no checking of the identity of the ClaimResponse returned for an
inquiry, e.g., that it matches the input or the original request.

These limitations may be removed in future versions of these tests. In the meantime, testers should consider these
requirements to be verified through attestation and should not represent their systems to have passed these tests
if these requirements are not met.

### Subscription Details

Subscription details in the PAS 2.0.1 specification are relatively underspecified and the
[2.2.1 version of the 
specification](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#subscription) 
makes significant changes, including requiring `full-resource` and updating details such as
the filter criteria.

Based on the immaturity of the 2.0.1 requirements around Subscriptions, the client 2.0.1 suite
implements and checks for the mechanics of Subscriptions and notifications, but does not look
closely at the details. For example, `id-only` and `full-resource` are supported and the filter
criteria format is not checked. The client 2.2.1 suite is more stringent.

Additionally, to test Subscriptions and pending scenarios, a new Subscription must be created for each
test session, which may require testers to re-initialize previously-created Subscriptions. Future versions
of these tests may relax this requirement and feedback on whether this would reduce burden and how this
might look are welcome.

### Future Details

The PAS IG places additional requirements on clients that are not currently tested by either or both
versions of the client suite, including

- Prior Authorization update scenarios (tested by the client v2.2.1 suite only)
- Requests for additional information handled through the CDex framework
- PDF, CDA, and JPG attachments
- Most details requiring manual review of the client system, e.g., the requirement that clinicians can update
  details of the prior authorization request before submitting them

These and any other requirements found in the PAS IG may be tested in future versions of these tests.

### Known Issues

Testing has identified issues with the source IG that result in spurious failures. 
Tests impacted by these issues have an indication in their documentations. The full
list of known issues can be found on the [repository's issues page with the 'source ig issue'
label](https://github.com/inferno-framework/davinci-pas-test-kit/labels/source%20ig%20issue).
