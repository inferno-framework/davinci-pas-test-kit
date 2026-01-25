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

*   **`client/`**: directory containing tests and logic specific to the client suites.
*   **`cross_suite/`**: directory containing logic shared by all suites.
*   **`server/`**: directory containing tests and logic specific to the server suites.
*   **`generator.rb` and `generator/`**: Holds the Ruby scripts and templates that create
    some of the test structure and content based on published IG content. Generated files are
    placed in the `generated/` folder under the `client/`, `cross_suite/`, and `server/` directories.
    See the [Test Generation Guide](Test-Generation-Guide) for more details on the generation scope
    and process.
*   **`igs/`**: directory containing the ig versions used to generate test content for suites within
    this test kit.
*   **`requirements/`**: directory containing the extractd requirements for this test kit.
*   **`version.rb`**: Specifies the version of the test kit.
*   **`metadata.rb`**: Contains metadata for the test kit, including its title, description
    (which appears in the Inferno UI), and suite IDs. This is a crucial file for how the test kit
    presents itself in the Inferno Framework.

### Shared Cross-Suite Code Organization

Key subdirectories and files within the `cross_suite/` folder include:

*   **`generated/`**: Contains metadata files generated from the PAS IG and used for must support tests.
*   **`must_support/`**: Contains base must support test logic used by all suites.
*   **`pas_bundle_validation.rb`**: Specific validation logic for PAS Bundles.
*   **`pas_subscription_validation.rb`**: Specific validation logic for PAS Subscriptions.
*   **`tags.rb`**: Tags used when storing and retrieving requests for validation.
*   **`urls.rb`**: Specific paths and addresses used and displayed by the tests.
*   **`validation_test.rb`**: Core logic for FHIR validation tests.
*   **`validator_suppressions.rb`**: Configuration for suppressing known, non-critical validation errors.

### Client Code Organization

Key subdirectories and files within the `client/` folder include:

*   **`certs/`**: Certificates and private keys used in the UDAP server simulation.
*   **`endpoints/`**: Contains code for managing the FHIR endpoints that Inferno exposes when simulating
    a PAS server during client testing.
*   **`generated/`**: Contains generated must support tests used by the client suites. The
    tests are organized by version and profile.
*   **`jobs/`**: Background jobs run in response to received messages, including 
    Subscription handshakes following creation and notifications following a pended Claim.
*   **`[version]`**: Contains the suite with all manually generated tests and logic for the
    version corresponding to the directory name. There will be one folder for each IG version
    supported.
*   **`client_input_descriptions.rb`**: Common descriptions for inputs within the client tests.
*   **`response_generator.rb`**: Logic used by the endpoints to generate responses when acting as
    a PAS server.
*   **`session_identification.rb`**: Logic used by client tests that receive requests to Inferno's
    simulated PAS server to make sure that those requests will be associated with the correct
    test session.
*   **`user_input_response.rb`**: Logic used by client tests that receive requests to Inferno's
    simulated PAS server to enable inputs provided by the tester to be returned by Inferno.

### Server Code Organization

Key subdirectories and files within the `server/` folder include:
*   **`generated/`**: Contains generated tests and groups used by the server suites, including
    the server suites themselves. The tests are organized by version and then profile when
    applicable.
*   **`[version]`**: Contains the manually generated tests and logic for the server suite
    version corresponding to the directory name. There will be one folder for each IG version
    supported.

### Additional Top-level Organization

*   **`config/presets/`**: Contains preset definitions used by the suites in this test kit.
*   **`docs/`**: Contains Markdown documentation files that are mirrored to the [GitHub wiki](/inferno-framework/davinci-pas-test-kit/wiki) for this repository.
*   **`spec/`**: Contains rspec-based unit tests for this test kit.

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
