require_relative 'claim_operation_logic'

module DaVinciPASTestKit
  class ClaimSubmitOperationTest < Inferno::Test
    include ClaimOperationLogic

    id :pas_claim_submit_operation_test
    title 'Submission of a claim to the $submit operation succeeds'
    description %(
        Server SHALL support PAS Submit requests: a POST interaction to
        the /Claim/$submit endpoint.
        This test submits a Prior Authorization Submit request to the server and verifies that a
        response is returned with HTTP status 2XX.
        The server SHOULD respond within 15 seconds.
      )

    input :pa_submit_request_payload,
          title: 'PAS Submit Request Payload',
          description: 'Insert Bundle to be sent for PAS Submit Request',
          type: 'textarea',
          optional: true
    input_order :server_endpoint, :smart_credentials

    def operation
      'submit'
    end

    run do
      run_operation_test(pa_submit_request_payload)
    end
  end
end
