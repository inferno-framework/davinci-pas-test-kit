# Da Vinci PAS Test Kit: Test Generation Guide

This document provides a comprehensive guide on how tests are generated for the
Da Vinci Prior Authorization Support (PAS) Test Kit, how to use the generator,
and some insights into its mechanics for maintainers.

## Overview

A portion of the server tests within the Da Vinci PAS Test Kit, particularly
those related to profile validation and must-support element checks, are
programmatically generated. This approach ensures that the test kit remains
aligned with the specific version of the PAS Implementation Guide (IG) it
targets and reduces the manual effort required to update tests when new IG
versions are released or when profiles change.

The test generator processes the formal artifacts of the PAS IG (such as StructureDefinitions and CapabilityStatements) to create executable test code.

Note that any time you make changes to content in the
`lib/davinci_pas/generator` directory, you will need to regenerate the tests. 
Do not make changes to the `generated` directory directly, because these will be
overwritten during the next generation.

## Prerequisites for Test Generation

Before you can generate tests, ensure you have the following set up:

1.  **Ruby Environment**: The test kit and its generator are written in Ruby. You'll need a working Ruby installation.
2.  **Bundler**: The project uses Bundler to manage Ruby gems (dependencies). Install it with `gem install bundler`.
3.  **Project Dependencies**: From the root directory of the `davinci-pas-test-kit`, run `bundle install` to install all required gems.
4.  **PAS IG Package**: You need the `.tgz` package file for the specific version of the Da Vinci PAS IG you want to generate tests for. This package contains the machine-readable artifacts (profiles, extensions, value sets, etc.).

## How to Generate Tests for an IG Version

Follow these steps to generate a new test suite or update an existing one for a specific PAS IG version:

1.  **Obtain the IG Package**:
    *   Download the `package.tgz` (or similarly named `.tgz` file) for the desired Da Vinci PAS IG version. This is typically available from the HL7 FHIR IG registry or the IG's publication page.

2.  **Place the IG Package**:
    *   Navigate to the `lib/davinci_pas_test_kit/igs/` directory within your local clone of the `davinci-pas-test-kit` repository.
    *   Place the downloaded `.tgz` file into this `igs/` directory.
    *   It's good practice to rename the file to clearly indicate the IG version, for example, `davinci_pas_2.0.1.tgz` or `davinci_pas_2.1.0.tgz`. The generator might infer the version from the filename or internal package metadata.

3.  **Run the Generator Task**:
    *   Open your terminal and navigate to the root directory of the `davinci-pas-test-kit`.
    *   Execute the Rake task for PAS test generation:
        ```bash
        bundle exec rake pas:generate
        ```
    *   This command will invoke the scripts located in `lib/davinci_pas_test_kit/generator/`.

4.  **Verify Generated Files**:
    *   After the generator runs, check the `lib/davinci_pas_test_kit/generated/` directory. You should see a new subdirectory corresponding to the IG version you targeted (e.g., `v2.0.1/`).
    *   Inside this version-specific directory, you'll find generated Ruby files containing test groups, profile validation tests, must-support tests, and other necessary components.
    *   Also, check `lib/davinci_pas_test_kit/metadata.rb` to ensure the new suite ID (if a new version was added) is registered.

5.  **Test the Generated Suite**:
    *   Run your local Inferno instance (`./run.sh` after `./setup.sh`).
    *   In the Inferno UI, you should now see the newly generated (or updated) test suite available for selection.
    *   Execute some of the generated tests to ensure they load correctly and behave as expected. Test against a reference implementation or sample data if possible.

## Generator Mechanics

The test generation logic resides primarily in the `lib/davinci_pas_test_kit/generator/` directory. Key components include:

*   **`ig_loader.rb`**: Responsible for loading and parsing the IG package (`.tgz` file), making its resources (StructureDefinitions, CapabilityStatements, etc.) accessible.
*   **`ig_metadata_extractor.rb` / `ig_metadata.rb`**: Extracts high-level metadata from the IG.
*   **`suite_generator.rb`**: Orchestrates the generation of an entire test suite for an IG version.
*   **`group_generator.rb` / `group_metadata.rb`**: Handles the creation of test groups within the suite.
*   **`must_support_test_generator.rb`**: Specifically generates tests for "must support" elements defined in profiles. It inspects StructureDefinitions to identify these elements and creates tests to verify their presence or handling.
*   **`validation_test_generator.rb`**: Generates tests that perform FHIR profile validation on resources.
*   **`naming.rb`**: Provides conventions for naming generated files, classes, and test IDs.
*   **Templates**: The generator likely uses ERB (Embedded Ruby) templates (often found within the `generator/templates/` subdirectory, though not explicitly listed in the initial file view) to structure the generated Ruby code for tests and groups.

The general process is:
1.  The Rake task invokes the main generator script.
2.  The IG package is loaded.
3.  Relevant resources (profiles, capability statements) are identified.
4.  For each profile, tests are generated for:
    *   Basic resource validation against the profile.
    *   Validation of "must support" elements.
    *   Potentially tests for specific operations or interactions defined in CapabilityStatements.
5.  These tests are organized into groups, and the groups form a test suite.
6.  The generated Ruby files are written to the `lib/davinci_pas_test_kit/generated/<ig_version>/` directory.

Maintaining or extending the generator requires a good understanding of Ruby,
the Inferno Framework's testing DSL (Domain Specific Language), and the
structure of FHIR Implementation Guide packages.
