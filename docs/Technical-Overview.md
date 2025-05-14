# Da Vinci PAS Test Kit: Technical Overview

This document provides a technical overview of the Da Vinci Prior Authorization Support (PAS) Test Kit, aimed at developers and contributors. It covers test design principles, code organization, related systems, and guidelines for testing code changes.

## Test Design Principles

The PAS Test Kit is built upon the Inferno Framework and adheres to its core design principles:

*   **FHIR-Native**: Tests are designed around FHIR interactions and data models.
*   **IG-Centric**: Validation is based on the requirements and profiles defined in the Da Vinci PAS Implementation Guide.
*   **Actor-Based Testing**: Separate test suites target client and server actors, simulating the counterpart system.
*   **Automated Validation**: Wherever possible, conformance is checked automatically. This includes FHIR resource validation, profile conformance, and workflow logic.
*   **Transparency**: Test logic and results are intended to be clear and understandable, aiding implementers in identifying issues.
*   **Extensibility**: The Inferno Framework allows for the creation of custom tests and test suites.

## Code Organization

The primary codebase for the PAS Test Kit resides within the `lib/davinci_pas_test_kit/` directory. Key subdirectories and files include:

*   **`client_suite.rb`**: Defines the main test suite for PAS clients.
*   **`metadata.rb`**: Contains metadata for the test kit, including its title, description (which appears in the Inferno UI), and suite IDs. This is a crucial file for how the test kit presents itself in the Inferno Framework.
*   **`version.rb`**: Specifies the version of the test kit.
*   **`docs/`**: Contains Markdown documentation files that are mirrored to the [GitHub wiki](/inferno-framework/davinci-pas-test-kit/wiki) for this repository.
*   **`generated/`**: Contains tests and supporting files that are programmatically generated from the PAS Implementation Guide artifacts (like CapabilityStatements and StructureDefinitions). This is a key part of the test kit's strategy to stay aligned with the IG. It's typically structured by IG version.
*   **`generator/`**: Holds the Ruby scripts and templates responsible for the test generation process. Files like `suite_generator.rb`, `group_generator.rb`, and `must_support_test_generator.rb` are central to this.
*   **`custom_groups/`**: This directory contains custom-defined test groups that are not automatically generated. These groups often contain complex workflow logic or specific scenarios that require manual test definition. It's often structured by IG version (e.g., `v2.0.1/`).
    *   Files like `pas_client_approval_group.rb`, `pas_server_subscription_setup.rb` define specific sequences of tests.
*   **`igs/`**: Stores the IG package files (e.g., `davinci_pas_2.0.1.tgz`) that the generator uses as input.
*   **`endpoints/`**: Contains code for managing the FHIR endpoints that Inferno exposes when acting as a server (e.g., for client testing). This might include endpoints for `$submit`, `$inquire`, and `Subscription` interactions.
*   **`jobs/`**: For background jobs, if any. For PAS, this could include tasks like sending delayed subscription notifications (e.g., `send_pas_subscription_notification.rb`).
*   **Supporting Logic Files**:
    *   `fhir_resource_navigation.rb`: Utilities for navigating FHIR resources.
    *   `must_support_test.rb`: Core logic for generating and running Must Support tests.
    *   `pas_bundle_validation.rb`: Specific validation logic for PAS bundles.
    *   `response_generator.rb`: Logic for Inferno to generate responses when acting as a server.
    *   `validation_test.rb`: Core logic for FHIR validation tests.
    *   `validator_suppressions.rb`: Configuration for suppressing known, non-critical validation errors.

## Related Systems and Dependencies

*   **Inferno Framework**: The foundational platform upon which this test kit is built. Knowledge of Inferno's architecture and development patterns is essential for significant contributions.
*   **HL7 FHIR**: The core standard for data exchange.
*   **Da Vinci PAS Implementation Guide**: The specific set of rules and profiles this test kit validates against.
*   **FHIR Java Validator**: Used for validating resource conformance.
*   **Terminology Server (`tx.fhir.org`)**: Used by the validator to resolve terminology and validate code bindings.
*   **Ruby**: The programming language used for Inferno and this test kit.
*   **RSpec**: The testing framework used for the test kit's own internal unit/integration tests (see `spec/` directory).

## Testing Code Changes (Development Workflow)

When making changes to the test kit itself, it's important to ensure the changes are correct and do not introduce regressions.

1.  **Understand the Scope**: Determine if your change affects generated tests, custom test groups, core logic, or documentation.
2.  **Make Code Changes**: Implement your fixes or new features.
3.  **Run RSpec Tests**:
    *   The test kit has its own suite of tests located in the `spec/` directory. These are RSpec tests that validate the test kit's internal logic, generators, etc.
    *   From the root directory of the test kit, you can typically run these tests using a command like `bundle exec rspec`.
    *   Ensure all RSpec tests pass before considering your changes complete.
4.  **Manual Testing (Using Inferno UI)**:
    *   Run your local Inferno instance (`run.sh` after `setup.sh`), or use the [developer-oriented method](https://inferno-framework.github.io/docs/getting-started/#development-with-ruby).
    *   Manually execute the test suites/groups affected by your changes against:
        *   The public reference implementations (if applicable).
        *   Any local test servers or client simulators you have.
        *   The provided Postman collection for client tests.
    *   This helps catch issues that RSpec tests might miss, especially those related to UI interactions or workflow logic as experienced by a user.
5.  **Test Generation (If Applicable)**:
    *   If you've modified the test generator (`lib/davinci_pas_test_kit/generator/`), you'll need to re-generate the affected tests:
        *   Ensure the relevant IG package is in `lib/davinci_pas_test_kit/igs/`.
        *   Run `bundle exec rake pas:generate`.
        *   Review the generated files for correctness.
        *   Run the re-generated tests in the Inferno UI.
6.  **Update Documentation**: If your changes affect user-facing behavior, test procedures, or technical details, update the relevant documentation files in `/docs/`. These will be automatically mirrored to the repository's [GitHub Wiki](https://github.com/inferno-framework/davinci-pas-test-kit/wiki).


## Contribution Guidelines

*   **Follow Existing Patterns**: Try to adhere to the coding style and architectural patterns already present in the test kit and the Inferno Framework.
*   **Write RSpec Tests**: For new logic or significant changes, add corresponding RSpec tests.
*   **Keep Documentation Updated**: Ensure your contributions are reflected in the documentation.
*   **Report Issues**: Use the [GitHub Issues page](https://github.com/inferno-framework/davinci-pas-test-kit/issues) for the repository to report bugs or suggest enhancements.
*   **Pull Requests**: Submit changes via pull requests for review.
*   **Update Documentation**: Please be sure to update all suite descriptions, test descriptions, the README, and the contents of the `./docs` folder of this repository along with code changes.

## Unusual Implementation Details

*   **X12 Dependency**: The PAS IG's reliance on proprietary X12 information for some terminology and semantics is a significant challenge. The test kit cannot directly validate these aspects and often relies on attestation or flags them as limitations.
*   **Test Data Input**: For server testing, the kit relies heavily on users providing their own conformant request bundles that are designed to elicit specific responses (approval, denial, etc.) from their server. This is because the exact business logic for these decisions is outside the scope of the FHIR IG.
