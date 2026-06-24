require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../../client/user_input_response'
require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientProcessingErrorResponseValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include UserInputResponse

      id :pas_client_v221_processing_error_response_validation_test
      title 'Processing Error Response Bundle is valid and contains error entries'
      description %(
        **USER INPUT VERIFICATION**: This test verifies input provided by the tester instead of the system under test.
        Errors encountered will be treated as a skip instead of a failure.

        This test verifies the conformity of the PAS Response Bundle returned by Inferno during the
        Processing Error workflow. The bundle is validated against the
        [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-response-bundle.html)
        profile. Additionally, it checks that the ClaimResponse contains at least one error entry,
        as required by the processing error scenario.

        Per IG §7.2.5, business errors that are a part of processing the 278 payload are
        represented in the mapping to the response bundle via the ClaimResponse error capability.

        **Limitations**

        Due to recognized errors in the PAS IG around extension context definitions,
        this test may not pass due to spurious errors of the form "The extension
        [extension url] is not allowed at this point". See [this
        issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues/11)
        for additional details.
      )
      simulation_verification

      run do
        load_tagged_requests(PROCESSING_ERROR_WORKFLOW_TAG, SUBMIT_TAG)
        skip_if requests.empty?,
                'No responses to verify because no $submit requests were received during the Processing Error test.'

        response_body = request.response_body
        skip_if response_body.blank?, 'The Processing Error response body is empty.'

        validate_pas_bundle_json(
          response_body,
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle',
          '2.2.1',
          'submit',
          'response_bundle',
          skips: true,
          message: "Invalid processing error response bundle provided in 'Processing Error Response Bundle JSON' input:"
        )

        bundle = FHIR.from_contents(response_body)
        skip_if bundle.nil?, 'The Processing Error response body could not be parsed as a FHIR resource.'

        claim_response_entry = bundle.entry&.find { |e| e&.resource&.resourceType == 'ClaimResponse' }
        skip_if claim_response_entry.nil?,
                'No ClaimResponse entry found in the Processing Error response bundle.'

        claim_response = claim_response_entry.resource
        skip_if claim_response.error.blank?,
                'The ClaimResponse in the Processing Error response bundle contains no error entries. ' \
                "The '#{input_title(:processing_error_response)}' input must include a ClaimResponse " \
                'with at least one error entry.'
      end
    end
  end
end
