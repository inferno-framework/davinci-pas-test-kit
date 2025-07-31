# Da Vinci Prior Authorization Support (PAS) Test Kit

The **Da Vinci Prior Authorization Support (PAS) STU 2.0.1 Test Kit** validates the 
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
adoption by the health IT community including EHR vendors, payer systems, health app
developers, and testing labs. It is built using the [Inferno
Framework](https://inferno-framework.github.io/). The Inferno Framework is
designed for reuse and aims to make it easier to build test kits for any
FHIR-based data exchange.

For comprehensive documentation, including detailed walkthroughs, overviews, and
technical references, please see the [Da Vinci PAS Test Kit
Documentation](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/).

## Getting Started

ASTP hosts a [public
instance](https://inferno.healthit.gov/suites/g10_certification) of this test
kit that developers and testers are welcome to use. However, users are
encouraged to download and run this tool locally to allow testing within private
networks and to avoid being affected by downtime of this shared resource.
Please see the [Local Installation
Instructions](#local-installation-instructions) section below for more
information.

## Status

These tests are a **DRAFT** and are intended to allow PAS implementers to perform 
preliminary checks of their implementations against PAS IG requirements and provide 
feedback on the tests. Future versions of these tests may validate other 
requirements and may change how these are tested.

Additional details on the IG requirements that underlie this test kit can be found in the [Inferno Requirements Tools](https://inferno-framework.github.io/docs/advanced-test-features/requirements.html),
including in [this spreadsheet](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/requirements/hl7.fhir.us.davinci-pas_2.0.1_requirements.xlsx).
The spreadsheet includes:

- a list of requirements extracted from the IG.
- the requirements tested by this DRAFT test kit.
- an analysis of which requirements are testable, including areas where testable requirements are weak or unclear.

## Getting Started

ASTP hosts a [public
instance](https://inferno.healthit.gov/test-kits/davinci-pas/) of this test
kit that developers and testers are welcome to use. However, users are
encouraged to download and run this tool locally to allow testing within private
networks and to avoid being affected by downtime of this shared resource.
Please see the [Local Installation
Instructions](#local-installation-instructions) section below for more
information.

Detailed step-by-step instructions for running the tests can be found in our walkthrough guides:
- [Client Testing Walkthrough](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Walkthrough)
- [Server Testing Walkthrough](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Walkthrough)

Additional information is provided in the [Da Vinci PAS Test Kit documentation](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/).

## Local Installation Instructions

- [Download an official release](https://github.com/inferno-framework/davinci-pas-test-kit/releases) of this test kit.
- Open a terminal in the directory containing the downloaded code.
- In the terminal, run `setup.sh`.
- In the terminal, run `run.sh`.
- Use a web browser to navigate to `http://localhost`.

More information on using Inferno Test Kits is available on the [Inferno
Framework documentation site](https://inferno-framework.github.io/docs).

### Multi-user Installations

The default configuration of this test kit uses SQLite for data persistence and
is optimized for running on a local machine with a single user. For
installations on shared servers that may have multiple tests running
simultaneously, please [configure the installation to use
PostgreSQL](https://inferno-framework.github.io/inferno-core/deployment/database.html#postgresql)
to ensure stability in this type of environment.

## Providing Feedback and Reporting Issues

We welcome feedback on the tests, including but not limited to the following areas:
- Validation logic, such as potential bugs, lax checks, and unexpected failures.
- Requirements coverage, such as requirements that have been missed, tests that necessitate features that the IG does not require, or other issues with the interpretation of the IG's requirements.
- User experience, such as confusing or missing information in the test UI.

Please report any issues with this set of tests in the [issues
section](https://github.com/inferno-framework/da-vinci-pas-test-kit/issues)
section of this repository.

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
