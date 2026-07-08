require_relative 'error_handling/pas_client_processing_error_submit_test'
require_relative 'error_handling/pas_client_processing_error_response_validation_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_attest'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientProcessingErrorGroup < Inferno::TestGroup
      id :pas_client_v221_processing_error_group
      title 'Processing Errors'
      description %(
        During these tests, the client will initiate a prior authorization
        request and show it can respond appropriately to a response containing
        one or more ClaimResponse.error entries.
      )
      run_as_group

      input :processing_error_response

      input_order :processing_error_response,
                  :client_id,
                  :session_url_path

      test from: :pas_client_v221_processing_error_submit_test
      test from: :pas_client_v221_request_bundle_validation_test,
           config: { options: { workflow_tag: PROCESSING_ERROR_WORKFLOW_TAG } }
      test from: :pas_client_v221_processing_error_response_validation_test
      test from: :pas_client_v221_response_attest,
           title: 'Check that the client handles the processing errors appropriately (Attestation)',
           description: %(
             This test provides the tester an opportunity to observe their client following
             the receipt of the response containing ClaimResponse.error entries and attest
             that the processing error details were made available to the appropriate users.
           ),
           config: { options: {
             workflow_tag: PROCESSING_ERROR_WORKFLOW_TAG,
             attest_message: 'I attest that the client system handles the processing error response ' \
                             'appropriately: the ClaimResponse error details are surfaced to the ' \
                             'appropriate users so that corrective action can be taken.'
           } }
    end
  end
end
