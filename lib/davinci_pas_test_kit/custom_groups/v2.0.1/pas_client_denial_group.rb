require_relative 'client_tests/pas_client_denial_submit_test'
require_relative 'client_tests/pas_client_response_attest'
require_relative 'client_tests/pas_client_response_bundle_validation_test'
require_relative 'client_tests/pas_client_request_bundle_validation_test'
require_relative '../../user_input_response'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientDenialGroup < Inferno::TestGroup
      include UserInputResponse
      id :pas_client_v201_denial_group
      title 'Demonstrate Denial Workflow'
      description %(
        Demonstrate the ability of the client to initiate a prior authorization
        request and respond appropriately to a 'denied' decision.
      )
      run_as_group

      input :denial_json_response, optional: true

      test from: :pas_client_v201_denial_submit_test
      test from: :pas_client_v201_request_bundle_validation_test,
           config: { options: { workflow_tag: DENIAL_WORKFLOW_TAG } }
      test from: :pas_client_v201_response_bundle_validation_test,
           config: { options: { workflow_tag: DENIAL_WORKFLOW_TAG } }
      test from: :pas_client_v201_response_attest,
           title: 'Check that the client registers the request as denied (Attestation)',
           description: %(
             This test provides the tester an opportunity to observe their client following
             the receipt of the denied response and attest that users are able to determine
             that the response has been denied.
           ),
           config: { options: {
             workflow_tag: DENIAL_WORKFLOW_TAG,
             attest_message: "I attest that the client system displays the submitted claim as 'denied'."
           } }
    end
  end
end
