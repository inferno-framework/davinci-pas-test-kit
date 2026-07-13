require_relative 'version'

module DaVinciPASTestKit
  class Metadata < Inferno::TestKit
    id :davinci_pas_test_kit
    title 'Da Vinci Prior Authorization Support (PAS) Test Kit'
    description <<~DESCRIPTION
      The Da Vinci Prior Authorization Support (PAS) Test Kit validates
      the conformance of both PAS client and server implementations to
      the Da Vinci PAS Implementation Guide. It includes suites covering the
      following versions:
      - [v2.0.1](https://hl7.org/fhir/us/davinci-pas/STU2/)
      - [v2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1/)

      <!-- break -->

      ## Status

      These tests are a **DRAFT** intended to allow PAS implementers to perform
      preliminary checks of their implementations against the PAS IG requirements and
      provide feedback on the tests. Future versions of these tests may validate other
      requirements and may change how these are tested.

      Additional details on the IG requirements that underlie this test kit can be
      found in the [Specification Requirements display within the testing UI](https://inferno-framework.github.io/docs/user-interface.html#specification-requirements)
      and other artifacts of Inferno's [requirements tracking tools](https://inferno-framework.github.io/docs/advanced-test-features/requirements.html).

      ## Additional Details

      Additional details about design, scope, and limitations of the suites within this
      test kit can be found on the [PAS Test Kit Wiki](https://github.com/inferno-framework/davinci-pas-test-kit/wiki)

      ## Reporting Issues

      Please report any issues with this set of tests in the [GitHub
      Issues](https://github.com/inferno-framework/davinci-pas-test-kit/issues)
      section of the
      [open source code repository](https://github.com/inferno-framework/davinci-pas-test-kit).
    DESCRIPTION
    suite_ids [
      :davinci_pas_server_suite_v201,
      :davinci_pas_server_suite_v221,
      :davinci_pas_client_suite_v201,
      :davinci_pas_client_suite_v221
    ]
    tags ['Da Vinci', 'PAS']
    last_updated LAST_UPDATED
    version VERSION
    maturity 'Low'
    authors ['Inferno Team']
    repo 'https://github.com/inferno-framework/davinci-pas-test-kit'
  end
end
