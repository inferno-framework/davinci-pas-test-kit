# Da Vinci PAS Test Kit: Test Generation Guide

This document provides a comprehensive guide on how tests are generated for the
Da Vinci Prior Authorization Support (PAS) Test Kit, how to use the generator,
and some insights into its mechanics for maintainers.

## Overview

A portion of the server and client tests within the Da Vinci PAS Test Kit, particularly
those related to profile validation and must-support element checks, are
programmatically generated. This approach ensures that the test kit remains
aligned with the specific version of the PAS Implementation Guide (IG) it
targets and reduces the manual effort required to update tests when new IG
versions are released or when profiles change.

The test generator processes the formal StructureDefinitions artifacts of the PAS IG
to create executable test code. Because the generator code can easily get complex
and difficult to maintain, the scope of the generated parts of each suite is kept
small, focusing on tests that get repeated for each profile or use case, mostly
must support tests. This means that some manual effort is still needed to create
test suites for a new version of the PAS IG.

Note that any time you make changes to content in the
`lib/davinci_pas/generator` directory, you will need to regenerate the tests. 
Do not make changes to any of the `client/generated`, `cross_suite/generated`, and `server/generated`
directories directly, because these will be overwritten during the next generation.

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
    *   This command will invoke the scripts located in `lib/davinci_pas_test_kit/generator.rb` and related files under `lib/davinci_pas_test_kit/generator/`.

4.  **Verify Generated Files**:
    *   After the generator runs, check the `generated/` directory under the
    `lib/davinci_pas_test_kit/client`, `lib/davinci_pas_test_kit/server`, and
    `lib/davinci_pas_test_kit/cross_suite` directories. Under each, you should see a new
    subdirectory corresponding to the IG version you targeted (e.g., `v2.0.1/`).
    *   Inside this version-specific directory, you'll find generated Ruby files containing test groups, profile validation tests, must-support tests, and other necessary components.
    *   Also, check `lib/davinci_pas_test_kit/metadata.rb` to ensure the new suite ID (if a new version was added) is registered.

5.  **Implement Non-generated Tests**
    *   Not all tests are generated automatically. Some require manual updates based on what if anything has changed in the IG. The generator may point to files that need to be created for the new version, or not generate containing classes. For example, the following entities currently must be manually created (NOTE: some may be able to be re-used across versions)
        - The root client suite class, all client non-must support tests, and the client request profiles must support test.
        - The server error tests, server request profiles must support test, and server subscription setup and conformance tests.
    *   Implement these entities using the patterns from prior versions and re-use and update them as needed. Changes in requirements may require changes in the generator code as well.

5.  **Test the Generated Suite**:
    *   Run your local Inferno instance (`./run.sh` after `./setup.sh`).
    *   In the Inferno UI, you should now see the newly generated (or updated) test suite available for selection.
    *   Execute some of the generated tests to ensure they load correctly and behave as expected. Test against a reference implementation or sample data if possible.

## Generator Mechanics

The test generation logic resides in the `lib/davinci_pas_test_kit/generator.rb` file that invokes specific generation logic within the `lib/davinci_pas_test_kit/generator/` directory.

The general process is:
1.  The Rake task invokes the main generator script.
2.  The IG package is loaded.
3.  Relevant resources (profiles, capability statements) are identified.
4.  For each profile, tests are generated for:
    *   Basic resource validation against the profile.
    *   Validation of "must support" elements.
    *   Potentially tests for specific operations or interactions defined in CapabilityStatements.
5.  These tests are organized into groups, and the groups form a test suite.
6.  The generated Ruby files are written to the `generated/<ig_version>/` directory under the
     `lib/davinci_pas_test_kit/client`, `lib/davinci_pas_test_kit/server`, and
    `lib/davinci_pas_test_kit/cross_suite` directories.

Maintaining or extending the generator requires a good understanding of Ruby,
the Inferno Framework's testing DSL (Domain Specific Language), and the
structure of FHIR Implementation Guide packages.

The following sections contain high-level descriptions of the purpose for each file under the `lib/davinci_pas_test_kit/generator/`.

### Generated Entities

*   **`must_support_test_generator.rb` and `templates/must_support.rb.erb`**: Generates individual must support test instances. A unique instances gets created for each profile and system (`client` and `server`) used by each combination of operation (`$submit` and `$inquire`) and direction (`request` and `response`).
*   **`client_must_support_group_generator.rb` and `templates/client_must_support_group.rb.erb`**: Generates must support test groups for the client. Separate classes are generated for the `$submit` and `$inquire` groups.
*   **`server_must_support_group_generator.rb` and `templates/server_must_support_group.rb.erb`**: Generates must support test groups for the server. A single class is generated which contains sub-groups for the `$submit` and `$inquire` tests.
*   **`use_case_group_generator.rb` and `templates/use_case_group.rb.erb`**: Generates classes for the server workflow groups (`approval`, `denial`, `pended`).
*   **`server_suite_generator.rb` and `templates/userver_suite.rb.erb`**: Generates a class for the server suite, referencing all necessary generated imports for the suite to operate.

### Shared Generator Components

*   **`ig_loader.rb` and `ig_resources.rb`**: Responsible for loading and parsing the IG package (`.tgz` file), making its resources (StructureDefinitions, CapabilityStatements, etc.) accessible.
*   **`ig_metadata_extractor.rb` and `ig_metadata.rb`**: Extracts high-level metadata from the IG and provides coordination between different generating components.
*   **`profile_metadata_extractor.rb` and `profile_metadata.rb` and `terminology_binding_metadata_extractor.rb`**: Extracts profile details which are used to drive the test generation. Note that these classes were built off of the [US Core test kit versions](https://github.com/inferno-framework/us-core-test-kit/blob/main/lib/us_core_test_kit/generator/group_metadata.rb) that collect more information, so not all of the details collected are used by the PAS generator.
*   **`descriptions.rb`**: shared content for descriptions used when generating tests, such as listing links to the related profiles.
*   **`must_support_target_profiles.rb`**: lists which profiles to include when checking must support requirements for each Bundle type.
