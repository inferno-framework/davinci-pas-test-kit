# Da Vinci Prior Authorization Support (PAS) v2.0.1 Test Kit

The Da Vinci Prior Authorization Support (PAS) STU 2.0.1 Test Kit validates the 
conformance of systems to the PAS STU 2.0.1 FHIR IG. The test kit includes
suites targeting each of the actors from the specification:

- Servers (payers): Inferno will act as a client and make a series of
  requests to the server under test.
- Clients (Provider systems, such as EMRs and other systems that place orders): 
  Inferno will act as a server, including waiting for the client to make requests 
  and responding back.

In each case, content provided by the system under test will be checked individually
for conformance and in aggregate to determine that the full set of features is
supported.

This test kit is [open source](#license) and freely available for use or
adoption by the health IT community including EHR vendors, health app
developers, and testing labs. It is built using the [Inferno
Framework](https://inferno-framework.github.io/). The Inferno Framework is
designed for reuse and aims to make it easier to build test kits for any
FHIR-based data exchange.

## Status

These tests are a **DRAFT** intended to allow PAS implementers to perform 
preliminary checks of their implementations against PAS IG requirements and provide 
feedback on the tests. Future versions of these tests may validate other 
requirements and may change how these are tested.

Additional details on the IG requirements that underlie this test kit, including those 
that are not currently tested, can be found in [this spreadsheet](lib/davinci_pas_test_kit/docs/PAS%20Requirements%20Interpretation.xlsx). The spreadsheet includes

- a list of requirements extracted from the IG.
- the requirements tested by this DRAFT test kit.
- an analysis of which requirements are testable, including areas where testable requirements are weak or unclear.

## Test Scope and Limitations

Neither the server nor client test suite included test the full scope of the PAS IG.
Documentation of what is currently tested and what is out of scope and why can be
found in the suite descriptions when the tests are run, or within this repository
for the [server](lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations)
and [client](lib/davinci_pas_test_kit/docs/client_suite_description_v201.md#testing-limitations).

### In-Scope Requirements

At a high-level, in-scope requirements include:

- The ability of the system to participate in end-to-end prior authorization
  workflows, including those resulting in approval or denial, including cases
  where the request goes through a pending status to allow for additional time
  for the decision to be made.
- The ability of the system to produce and receive (currently server tests only)
  all PAS-defined profiles and their must support elements.

### Out-of-Scope Requirements

Out of scope requirements from the IG that are not yet tested include:

- Subscriptions (see details [here](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html#subscription))
- Prior Authorization update workflows (see details [here](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html#updating-authorization-requests))
- Requests for additional information handled through the CDex framework ([see detail here](https://hl7.org/fhir/us/davinci-pas/STU2/additionalinfo.html))
- PDF, CDA, and JPG attachments (see details in the 3rd paragraph [here](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html#prior-authorization-submission))
- US Core profile support for supporting information (see details [here](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html#integration-with-other-implementation-guides))
- (Server) Inquiry matching and subsetting logic (see details in the 2nd paragraph and 2 bullet [here](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html#prior-authorization-inquiries))
- (Server) Inquiry requests from non-submitting systems (see details in the 3rd paragraph [here](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html#pended-authorization-responses))
- (Server) Collection and dissemination of metrics (see details [here](https://hl7.org/fhir/us/davinci-pas/STU2/metrics.html))
- (Client) The ability to handle responses containing all PAS-defined profiles and must support elements (see details under the 3rd bullet [here](https://hl7.org/fhir/us/davinci-pas/STU2/background.html#must-support))
- (Client) Most details requiring manual review of the client system, e.g., the requirement that clinicians can update details of the prior authorization request before submitting them (see details in the 1st paragraph [here](https://hl7.org/fhir/us/davinci-pas/STU2/usecases.html#submit-prior-authorization))

### Limitations

A primary limitation of these tests involves the proprietary nature of the X12 specification that the PAS IG relies upon. See details at the top of the 
[IG home page](https://hl7.org/fhir/us/davinci-pas/STU2/index.html). This reliance 
on proprietary information that is not publicly available means that this test kit:

- Cannot verify the correct usage of X12-based terminology: terminology requirements for all elements bound to X12
  value sets will not be validated
- Cannot verify the meaning of codes: validation that a given response conveys something specific, e.g., approval
  or pending, is not performed
- Cannot verify matching semantics on inquiries: no checking of the identity of the ClaimResponse returned for an
  inquiry, e.g., that it matches the input or the original request.

These limitations may be removed in future versions of these tests. In the meantime, testers should consider these
requirements to be verified through attestation and should not represent their systems to have passed these tests
if these requirements are not met.

## How to Run

Use either of the following methods to run the suites within this test kit.
If you would like to try out the tests but don’t have a PAS implementation, 
the test home pages include instructions for trying out the tests, including

- For server testing: a [public reference implementation](https://prior-auth.davinci.hl7.org/fhir)
  ([code on github](https://github.com/HL7-DaVinci/prior-auth))
- For client testing: a [sample postman collection](config/PAS%20Test%20Kit%20Client%20Test%20Demo.postman_collection.json)

Detailed instructions can be found in the suite descriptions when the tests
are run, or within this repository for the 
[server](lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#running-the-tests) and
[client](lib/davinci_pas_test_kit/docs/client_suite_description_v201.md#running-the-tests).

### ONC Hosted Instance

You can run the PAS test kit via the [ONC Inferno](https://inferno.healthit.gov/test-kits/davinci-pas/) website by choosing the “Da Vinci Prior Authorization Support (PAS) v2.0.1” test kit.

### Local Inferno Instance

- Download the source code from this repository.
- Open a terminal in the directory containing the downloaded code.
- In the terminal, run `setup.sh`.
- In the terminal, run `run.sh`.
- Use a web browser to navigate to `http://localhost`.

## Providing Feedback and Reporting Issues

We welcome feedback on the tests, including but not limited to the following areas:
- Validation logic, such as potential bugs, lax checks, and unexpected failures.
- Requirements coverage, such as requirements that have been missed, tests that necessitate features that the IG does not require, or other issues with the [interpretation](lib/davinci_pas_test_kit/docs/PAS%20Requirements%20Interpretation.xlsx) of the IG's requirements.
- User experience, such as confusing or missing information in the test UI.

Please report any issues with this set of tests in the issues section of this repository.

## Development

To make updates and additions to this test kit, see the 
[Inferno Framework Documentation](https://inferno-framework.github.io/docs/),
particularly the instructions on 
[development with Ruby](https://inferno-framework.github.io/docs/getting-started/#development-with-ruby).

### Test Generation

The Davinci PAS Test Kit has an implemeneted test generator that create some of the
tests in this kit from the capability statement and profiles in the IG. It
extracts necessarry data elements from Davinci Prior Authorization Support Implementation Guide archive files and generates tests accordingly. The repo currently contains
suites for IG versions 2.0.1.

To generate a test suite for a different Davinci PAS IG version:

- Navigate to `DAVINCI-PAS-Test-Kit/lib/davinci_pas_test_kit/igs/`
- Drop your package.tgz file for the IG version into this folder. You may want to rename it before hand.
- Run the command `bundle exec rake pas:generate` to run the generator.
- Run Inferno and verify that your new suite was generated and is available as an option

## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.