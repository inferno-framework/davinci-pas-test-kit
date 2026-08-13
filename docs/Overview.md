# Da Vinci PAS Test Kit Overview

This document provides a high-level overview of the Da Vinci Prior Authorization Support (PAS) Test Kit, its purpose, and general testing approach.

## Purpose

The Da Vinci PAS Test Kit is designed to validate the conformance of healthcare IT systems against
the HL7 FHIR Da Vinci Prior Authorization Support (PAS) Implementation Guide (IG) and includes suites
for both [v2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/) and [v2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/)
of the specification. It helps implementers ensure their systems can correctly participate in electronic
prior authorization workflows as defined by the PAS IG.

The test kit is built using the [Inferno Framework](https://inferno-framework.github.io/), an open-source platform for building FHIR-based test kits.

## Test Kit Structure

The PAS Test Kit includes two main test suites:

* **Server Test Suite**: For systems acting as payers (see [Server Details](Server-Details.md) for more information)
* **Client Test Suite**: For systems acting as providers (see [Client Details](Client-Details.md) for more information)

## General Testing Approach

The test kit validates systems through:

1. **Workflow Simulation**: Tests guide the system through key PAS workflows including:
   * Prior authorization request submission and response handling
   * Approval, denial, and pended decision flows
   * Error condition handling

2. **Data Conformance**:
   * Validation of must-support elements in PAS-defined FHIR profiles
   * FHIR resource validation using the official FHIR validator
   * Verification of proper Bundle structure and references

3. **Authentication**:
   * Support for SMART Backend Services
   * UDAP B2B client credentials flow
   * Other authentication methods via attestation

## Test Scope and Limitations

This test kit is a **DRAFT**. While it covers core aspects of the PAS IG, there are known limitations.

The test kit currently focuses on validating core end-to-end prior authorization
workflows, including the submission and handling of responses for prior
authorization requests (approval, denial, pended). It also covers FHIR profile
conformance, validation of must-support elements as defined in PAS IG profiles,
basic subscription mechanics for pended request notifications, and core
authentication flows like SMART Backend Services and UDAP B2B.

Several areas are generally considered out of scope for automated testing. This
includes the proprietary details of X12 transactions, such as X12-based
terminology validation and X12-based
matching logic. Additionally, not all workflows and requirements are covered
by all suites in this test kit.

For a details on specific specific limitations, detailed requirements, and known
issues, please consult the following resources: 
- [Client Testing Limitations](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#testing-limitations)
- [Server Testing Limitations](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Details#testing-limitations)
- Relevant [requirements](https://inferno-framework.github.io/docs/advanced-test-features/requirements.html)
  including those in the PAS Requirements Spreadsheets
   - [v2.0.1](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/requirements/hl7.fhir.us.davinci-pas_2.0.1_requirements.xlsx)
   - [v2.2.1](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/requirements/hl7.fhir.us.davinci-pas_2.2.1_requirements.xlsx)
- [PAS Test Kit GitHub Issues page](https://github.com/inferno-framework/davinci-pas-test-kit/issues).

## Conformance Criteria & Interpreting Results

A test run is considered successful if all mandatory tests pass:
* **Passing Tests**: Indicate expected behavior for specific scenarios
* **Failing Tests**: Indicate deviations from PAS IG requirements
* **Warnings**: Highlight potential concerns that require manual review
* **Skipped Tests**: Occur when prerequisites are not met

Given the known limitations, especially regarding X12, passing all automated tests does **not**
solely constitute full PAS IG conformance.

For specific testing prerequisites and detailed test descriptions, refer to:
* [Client v2.0.1 Instructions](Client-Instructions-v2.0.1.md)
* [Client v2.2.1 Instructions](Client-Instructions-v2.2.1.md)
* [Server v2.0.1 Instructions](Server-Instructions-v2.0.1.md)
* [Server v2.2.1 Instructions](Server-Instructions-v2.2.1.md)
