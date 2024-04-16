require_relative 'client_tests/pas_client_pended_submit_test'
require_relative 'client_tests/pas_client_pended_submit_response_attest'
require_relative 'client_tests/pas_client_pended_inquire_test'
require_relative 'client_tests/pas_client_pended_inquire_response_attest'
require_relative '../../generated/v2.0.1/client_tests/client_pended_pas_response_bundle_validation_test'
require_relative '../../generated/v2.0.1/client_tests/client_pas_request_bundle_validation_test'
require_relative '../../generated/v2.0.1/client_tests/client_pended_pas_inquiry_request_bundle_validation_test'
require_relative '../../user_input_response'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedGroup < Inferno::TestGroup
      include UserInputResponse
      id :pas_client_v201_pended_group
      title 'Demonstrate Pended Workflow'
      description %(
        Demonstrate the ability of the client to initiate a prior authorization
        request and respond appropriately to a 'pended' decision, including
        waiting for a notification that an update has been made (not currently
        implemented) and making an inquiry request to retrieve the final result.
      )
      run_as_group

      input :pended_json_response,
            title: 'Claim pended response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              The response provided will be validated against the PAS Response Bundle profile. If determined to be
              invalid, a validation message will be returned, and the test group will be skipped.
            )

      test from: :pas_client_v201_pended_submit_test,
           receives_request: :pended_claim,
           respond_with: :pended_json_response

      test from: :pas_client_v201_pended_pas_response_bundle_validation_test

      test from: :pas_client_v201_pas_request_bundle_validation_test,
           uses_request: :pended_claim

      test from: :pas_client_v201_pended_submit_response_attest,
           uses_request: :pended_claim

      test from: :pas_client_v201_pended_inquire_test,
           uses_request: :pended_claim,
           receives_request: :pended_inquiry

      test from: :pas_client_v201_pended_pas_inquiry_request_bundle_validation_test,
           uses_request: :pended_inquiry

      test from: :pas_client_v201_pended_inquire_response_attest,
           uses_request: :pended_inquiry
    end
  end
end
