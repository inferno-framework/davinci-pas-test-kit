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

### In-Scope (High-Level)

* End-to-end prior authorization workflows
* Profile conformance and must-support element validation
* Basic subscription mechanics for pended request notifications
* Core authentication flows

### Key Out-of-Scope Requirements

* **Private X12 Details**: Due to proprietary nature:
  * X12-based terminology usage validation
  * Semantic meaning of X12 codes
  * X12-based matching logic
* **Additional Workflows/Features**:
  * Prior Authorization Updates (`Claim/$update`)
  * Requests for Additional Information (RFAI)
  * Attachments (PDF, CDA, JPG)
  * US Core Profile Support
* **Advanced Subscription Details**: While basic mechanics are tested, some v2.0.1 subscription requirements are not deeply validated

For a detailed, up-to-date list of specific requirements and known issues, please refer to:
* The [PAS Requirements Interpretation Spreadsheet](../tree/main/lib/davinci_pas_test_kit/docs/PAS%20Requirements%20Interpretation.xlsx)
* The [test kit's GitHub Issues page](https://github.com/HL7/davinci-pas-test-kit/issues)

## Conformance Criteria & Interpreting Results

A test run is considered successful if all mandatory tests pass:
* **Passing Tests**: Indicate expected behavior for specific scenarios
* **Failing Tests**: Indicate deviations from PAS IG requirements
* **Warnings**: Highlight potential concerns without failing tests
* **Skipped Tests**: Occur when prerequisites are not met

Given the known limitations, especially regarding X12, passing all automated tests does **not** solely constitute full PAS IG conformance. Systems should also meet requirements verified through attestation or other means.

For specific testing prerequisites and detailed test descriptions, refer to:
* [Client Walkthrough](Client-Walkthrough.md)
* [Server Walkthrough](Server-Walkthrough.md)
