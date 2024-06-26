require_relative 'client_tests/pas_client_denial_submit_test'
require_relative 'client_tests/pas_client_denial_submit_response_attest'
require_relative '../../generated/v2.0.1/client_tests/client_denial_pas_response_bundle_validation_test'
require_relative '../../generated/v2.0.1/client_tests/client_pas_request_bundle_validation_test'
require_relative '../../user_input_response'

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
              The response provided will be validated against the PAS Response Bundle profile. If determined to be
              invalid, a validation message will be returned, and the test group will be skipped.
            )

      test from: :pas_client_v201_denial_submit_test,
           receives_request: :denial_claim,
           respond_with: :denial_json_response

      test from: :pas_client_v201_denial_pas_response_bundle_validation_test

      test from: :pas_client_v201_pas_request_bundle_validation_test,
           uses_request: :denial_claim

      test from: :pas_client_v201_denial_submit_response_attest,
           uses_request: :denial_claim
    end
  end
end
