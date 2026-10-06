require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../../client/user_input_response'
require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientProcessingErrorResponseValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include UserInputResponse

      id :pas_client_v221_processing_error_response_validation_test
      title '$submit response Bundle has the correct structure and contains error entries'
      description %(
        This test verifies input provided by the tester instead of the system under test.
        Errors encountered will be treated as a skip instead of a failure.

        This test verifies the conformity of the PAS Response Bundle returned by Inferno during the
        Processing Error scenario. The bundle is validated against the
        [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-pas-response-bundle.html)
        profile. Additionally, it checks that the ClaimResponse contains at least one error entry,
        as required by the processing error scenario.

        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#prior-authorization-transaction-error-handling)
        that business errors that are a part of processing the 278 payload are
        represented in the mapping to the response bundle via the ClaimResponse error capability.
      )
      simulation_verification

      run do
        load_tagged_requests(PROCESSING_ERROR_WORKFLOW_TAG, SUBMIT_TAG)
        skip_if requests.empty?,
                'No responses to verify because no $submit requests were received during the Processing Error test.'

        response_body = request.response_body
        skip_if response_body.blank?, 'The Processing Error response body is empty.'

        message = "Invalid processing error response bundle provided in 'Processing Error Response Bundle JSON' input:"
        begin
          JSON.parse(response_body)
        rescue JSON::ParserError, TypeError
          skip "#{message} Invalid JSON.".strip
        end

        bundle = FHIR.from_contents(response_body)
        skip_if !bundle.is_a?(FHIR::Bundle),
                "#{message} Unexpected resource type: expected Bundle, but received #{bundle&.resourceType}.".strip

        messages.concat(perform_bundle_validation(bundle, 'submit', 'response', '2.2.1'))
        skip_if error_messages?,
                "#{message} Bundle and/or entry resources are not conformant. Check messages for issues found.".strip

        claim_response = bundle&.entry&.find { |e| e&.resource&.resourceType == 'ClaimResponse' }&.resource
        skip_if claim_response&.error.blank?,
                'The ClaimResponse in the Processing Error response bundle contains no error entries. ' \
                "The '#{input_title(:processing_error_response)}' input must include a ClaimResponse " \
                'with at least one error entry.'
      end
    end
  end
end
