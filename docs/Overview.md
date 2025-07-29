# Da Vinci PAS Test Kit Overview

This document provides a high-level overview of the Da Vinci Prior Authorization Support (PAS) Test Kit, its purpose, and general testing approach.

## Purpose

The Da Vinci PAS Test Kit is designed to validate the conformance of healthcare IT systems against [version 2.0.1 of the HL7 FHIR Da Vinci Prior Authorization Support (PAS) Implementation Guide (IG)](https://hl7.org/fhir/us/davinci-pas/STU2/). It helps implementers ensure their systems can correctly participate in electronic prior authorization workflows as defined by the PAS IG.

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
terminology validation, the semantic meaning of X12 codes, and X12-based
matching logic. Additional workflows and features not currently covered include
Prior Authorization Updates (`Claim/$update`), comprehensive handling of
Requests for Additional Information (RFAI), processing of various attachment
types (PDF, CDA, JPG), full US Core Profile support, and advanced subscription
details beyond basic mechanics.

For a details on specific specific limitations, detailed requirements, and known
issues, please consult the following resources: the [Client Testing
Limitations](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details#testing-limitations),
the [Server Testing
Limitations](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Details#testing-limitations),
the [PAS Requirements Spreadsheet
Spreadsheet](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/requirements/hl7.fhir.us.davinci-pas_2.0.1_requirements.xlsx),
and the project's [GitHub Issues
page](https://github.com/inferno-framework/davinci-pas-test-kit/issues).

## Conformance Criteria & Interpreting Results

A test run is considered successful if all mandatory tests pass:
* **Passing Tests**: Indicate expected behavior for specific scenarios
* **Failing Tests**: Indicate deviations from PAS IG requirements
* **Warnings**: Highlight potential concerns that require manual review
* **Skipped Tests**: Occur when prerequisites are not met

Given the known limitations, especially regarding X12, passing all automated tests does **not** solely constitute full PAS IG conformance. Systems should also meet requirements verified through attestation or other means.

For specific testing prerequisites and detailed test descriptions, refer to:
* [Client Walkthrough](Client-Walkthrough.md)
* [Server Walkthrough](Server-Walkthrough.md)
