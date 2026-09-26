require_relative 'workflows/pas_client_denial_submit_test'
require_relative 'workflows/pas_client_response_attest'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative '../user_input_response'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientDenialGroup < Inferno::TestGroup
      include UserInputResponse

      id :pas_client_v221_denial_group
      title 'Denial Workflow'
      description %(
        During these tests, the client system will initiate a prior authorization
        request and show it can react appropriately to a 'denied' decision.
      )
      run_as_group

      input :denial_json_response, optional: true

      input_order :denial_json_response,
                  :client_id,
                  :session_url_path

      test from: :pas_client_v221_denial_submit_test
      test from: :pas_client_v221_response_attest,
           title: 'PAS client displays the request as "denied"',
           description: %(
             During this test, the tester will observe the client system following
             the receipt of the denied response and attest that users are able to determine
             that the response has been denied.
           ),
           config: { options: {
             workflow_tag: DENIAL_WORKFLOW_TAG,
             operation_tag: SUBMIT_TAG,
             attest_message: "I attest that the client system displays the submitted claim as 'denied', meaning " \
                             'that the user cannot proceed with ordering or providing the requested service without ' \
                             'making adjustments and submitting for further review.'
           } }
      test from: :pas_client_v221_request_bundle_validation_test,
           config: { options: { workflow_tag: DENIAL_WORKFLOW_TAG } }
      test from: :pas_client_v221_response_bundle_validation_test,
           config: { options: { workflow_tag: DENIAL_WORKFLOW_TAG } }
    end
  end
end
