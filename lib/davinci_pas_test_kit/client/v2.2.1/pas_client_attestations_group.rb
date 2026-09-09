require_relative 'attestations/attestation_instructions'
require_relative 'attestations/client_data_element_expectations_attestation_test'
require_relative 'attestations/client_provider_review_attestation_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientAttestationsGroup < Inferno::TestGroup
      id :pas_client_v221_attestations
      title 'Visual Inspection and Attestation'
      description %(
        Each test in this group asks the tester to confirm system conformance to one or more
        requirements from the [PAS v2.2.1 Implementation Guide](https://hl7.org/fhir/us/davinci-pas/2.2.1).
        The tester attests that the client system under test meets the statement by selecting "Yes",
        and may record supporting details in the accompanying notes field. Selecting "No" fails the
        test. Notes provided are recorded in the test result.

        Testers are responsible for confirming that their system meets all requirements associated with a test
        before selecting "Yes" on the attestation input with the same name as the test. The text of the
        attested requirement(s) for each input can be reviewed by clicking the "View Specification Requirements" link
        in the "About" tab of the test with the same name.
      )
      input_instructions ATTESTATION_INPUT_INSTRUCTIONS

      test from: :pas_client_v221_data_element_expectations_attestation
      test from: :pas_client_v221_provider_review_attestation
    end
  end
end
