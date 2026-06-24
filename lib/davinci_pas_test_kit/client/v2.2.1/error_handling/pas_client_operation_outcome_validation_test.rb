require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientOperationOutcomeValidationTest < Inferno::Test
      id :pas_client_v221_operation_outcome_validation_test
      title 'Operation Failure OperationOutcome is valid'
      description %(
        **USER INPUT VERIFICATION**: This test verifies input provided by the tester instead of the system under test.
        Errors encountered will be treated as a skip instead of a failure.

        This test verifies the validity of the OperationOutcome returned by Inferno during the
        Operation Failure workflow. The OperationOutcome is validated against the base FHIR R4
        OperationOutcome resource definition — no PAS-specific profile is required.

        Per IG §7.2.5, when a 4XX response is returned, an OperationOutcome SHALL be included
        that details why the bundle could not be processed.
      )
      simulation_verification

      run do
        load_tagged_requests(OPERATION_FAILURE_WORKFLOW_TAG, SUBMIT_TAG)
        skip_if requests.empty?,
                'No responses to verify because no $submit requests were received during the Operation Failure test.'

        response_body = request.response_body
        skip_if response_body.blank?, 'The Operation Failure response body is empty.'

        operation_outcome = FHIR.from_contents(response_body)
        skip_if operation_outcome.nil?,
                'The Operation Failure response body could not be parsed as a FHIR resource.'
        skip_if !operation_outcome.is_a?(FHIR::OperationOutcome),
                "Expected an OperationOutcome but received #{operation_outcome.resourceType}."

        resource_is_valid?(resource: operation_outcome)
      end
    end
  end
end
