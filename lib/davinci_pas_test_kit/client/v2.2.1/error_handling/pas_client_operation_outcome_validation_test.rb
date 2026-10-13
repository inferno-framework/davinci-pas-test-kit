require_relative '../../../cross_suite/tags'
require_relative '../../../cross_suite/validator_configuration'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientOperationOutcomeValidationTest < Inferno::Test
      id :pas_client_v221_operation_outcome_validation_test
      title 'Response OperationOutcome has the correct structure and content'
      description %(
        This test verifies the validity of the OperationOutcome returned by Inferno during the
        Operation Failure scenario. The OperationOutcome is validated against the base FHIR R4
        OperationOutcome resource definition — no PAS-specific profile is required.

        To ensure that the PAS client is driving its behavior only based on standard
        PAS information, custom extensions are not allowed within the response.

        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#prior-authorization-transaction-error-handling)
        that when a 4XX response is returned, an OperationOutcome **SHALL** be included
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

        skip_if !resource_is_valid?(resource: operation_outcome, validator: NO_CUSTOM_EXTENSIONS_VALIDATOR),
                'The OperationOutcome returned during the Operation Failure scenario is not conformant ' \
                'with the base FHIR R4 OperationOutcome resource definition or contains custom extensions. ' \
                'See Messages for details.'
      end
    end
  end
end
