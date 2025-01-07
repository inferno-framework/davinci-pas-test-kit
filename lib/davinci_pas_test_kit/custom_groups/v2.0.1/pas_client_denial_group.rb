require_relative 'client_tests/pas_client_denial_submit_test'
require_relative 'client_tests/pas_client_denial_submit_response_attest'
require_relative 'client_tests/pas_client_denial_pas_response_bundle_validation_test'
require_relative 'client_tests/pas_client_pas_request_bundle_validation_test'
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

      input :denial_json_response,
            title: 'Claim denied response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $submit requests during this test
              to indicate that the request has been denied.
              It will be updated to make creation timestamps current.
              If not provided, a denial response will be generated from the submitted Claim.
              In either case, the response will be validated against the PAS Response Bundle profile.
            )

      test from: :pas_client_v201_denial_submit_test
      test from: :pas_client_v201_pas_request_bundle_validation_test,
           config: { options: { workflow_tag: DENIAL_WORKFLOW_TAG } }
      test from: :pas_client_v201_denial_pas_response_bundle_validation_test
      test from: :pas_client_v201_denial_submit_response_attest
    end
  end
end
