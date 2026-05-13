require_relative 'claim_operation_logic'

module DaVinciPASTestKit
  class ClaimInquireOperationTest < Inferno::Test
    include ClaimOperationLogic

    id :pas_claim_inquire_operation_test
    title 'Submission of a claim to the $inquire operation succeeds'
    description %(
        Server SHALL support PAS Inquiry requests: a POST interaction to
        the /Claim/$inquire endpoint.
        This test submits a Prior Authorization Inquiry request to the server and verifies that a
        response is returned with HTTP status 2XX.
      )

    input :pa_inquire_request_payload,
          title: 'PAS Inquire Request Payload',
          description: 'Insert Bundle to be sent for PAS Inquire Request',
          type: 'textarea',
          optional: true
    input_order :server_endpoint, :smart_credentials

    def operation
      'inquire'
    end

    run do
      run_operation_test(pa_inquire_request_payload)
    end
  end
end
