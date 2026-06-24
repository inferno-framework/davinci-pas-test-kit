require_relative 'error_handling/pas_client_operation_failure_submit_test'
require_relative 'error_handling/pas_client_operation_outcome_validation_test'
require_relative 'workflows/pas_client_response_attest'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientOperationFailureGroup < Inferno::TestGroup
      id :pas_client_v221_operation_failure_group
      title 'Operation Failure'
      description %(
        During these tests, the client will initiate a prior authorization
        request and show it can respond appropriately to an operation failure response —
        a non-2XX HTTP status code accompanied by an OperationOutcome resource.
      )
      run_as_group

      input :operation_failure_operation_outcome
      input :operation_failure_http_status, optional: true

      input_order :operation_failure_operation_outcome,
                  :operation_failure_http_status,
                  :client_id,
                  :session_url_path

      test from: :pas_client_v221_operation_failure_submit_test
      test from: :pas_client_v221_operation_outcome_validation_test
      test from: :pas_client_v221_response_attest,
           title: 'Check that the client handles the operation failure appropriately (Attestation)',
           description: %(
             This test provides the tester an opportunity to observe their client following
             the receipt of the operation failure response and attest that the error details
             from the OperationOutcome were made available to the appropriate users (e.g.,
             technical staff, not the clinical end user).
           ),
           config: { options: {
             workflow_tag: OPERATION_FAILURE_WORKFLOW_TAG,
             attest_message: 'I attest that the client system handles the operation failure response ' \
                             'appropriately: the OperationOutcome details are available to technical staff ' \
                             'for review and the clinical end user is informed that the submission could ' \
                             'not be processed.'
           } }
    end
  end
end
