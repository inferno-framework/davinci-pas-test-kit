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

**For comprehensive documentation, including detailed guides, overviews, and technical references, please see our [Da Vinci PAS Test Kit Main Documentation](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/).**

## Status

These tests are a **DRAFT** intended to allow PAS implementers to perform 
preliminary checks of their implementations against PAS IG requirements and provide 
feedback on the tests. Future versions of these tests may validate other 
requirements and may change how these are tested.

Additional details on the IG requirements that underlie this test kit, including those 
that are not currently tested, can be found in [this spreadsheet](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/PAS-Requirements-Interpretation.xlsx). The spreadsheet includes

- a list of requirements extracted from the IG.
- the requirements tested by this DRAFT test kit.
- an analysis of which requirements are testable, including areas where testable requirements are weak or unclear.

## Test Scope and Limitations

Neither the server nor client test suite included test the full scope of the PAS IG.
A detailed discussion of the test scope, in-scope requirements, out-of-scope requirements, and known limitations (including those related to X12) can be found in the [Test Kit Overview](/inferno-framework/davinci-pas-test-kit/wiki/Overview) document.
Briefly, documentation of what is currently tested and what is out of scope can also be
found in the suite descriptions when the tests are run, or within this repository
for the [server](./tree/main/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations)
and [client](./tree/main/lib/davinci_pas_test_kit/docs/client_suite_description_v201.md#testing-limitations).

## Getting Started

Use either of the following methods to run the suites within this test kit.
If you would like to try out the tests but don’t have a PAS implementation, 
the test home pages include instructions for trying out the tests, including

- For server testing: a [public reference implementation](https://prior-auth.davinci.hl7.org/fhir)
  ([code on github](https://github.com/HL7-DaVinci/prior-auth))
- For client testing: a [sample postman collection](./tree/main/docs/demo/PAS%20Client%20Suite%20Demonstration.postman_collection.json)

Detailed step-by-step instructions for running the tests can be found in our walkthrough guides:
- [Client Testing Walkthrough](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Walkthrough)
- [Server Testing Walkthrough](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Walkthrough)

Summary instructions are also available in the suite descriptions when the tests
are run, or within this repository for the 
[server](./tree/main/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#running-the-tests) and
[client](./tree/main/lib/davinci_pas_test_kit/docs/client_suite_description_v201.md#running-the-tests).

### ASTP Hosted Instance

You can run the PAS test kit via the ASTP hosted public [Inferno on HealthIT.gov](https://inferno.healthit.gov/test-kits/davinci-pas/) site.

### Local Inferno Instance

- Download the source code from this repository.
- Open a terminal in the directory containing the downloaded code.
- In the terminal, run `setup.sh`.
- In the terminal, run `run.sh`.
- Use a web browser to navigate to `http://localhost`.

## Providing Feedback and Reporting Issues

We welcome feedback on the tests, including but not limited to the following areas:
- Validation logic, such as potential bugs, lax checks, and unexpected failures.
- Requirements coverage, such as requirements that have been missed, tests that necessitate features that the IG does not require, or other issues with the [interpretation](./tree/main/lib/da_vincipas_test_kit/docs/PAS-Requirements-Interpretation.xlsx) of the IG's requirements.
- User experience, such as confusing or missing information in the test UI.

Please report any issues with this set of tests in the issues section of this repository.

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
