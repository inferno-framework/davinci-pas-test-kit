module DaVinciPASTestKit
  module DaVinciPASV201
    class ClaimInquiryOperationTest < Inferno::Test

      id :pas_v201_claim_inquiry_operation_test
      title 'Submission of a claim to the $inquire operation succeeds'
      description %(
        Server SHALL support PAS Inquiry requests: a POST interaction to
        the /Claim/$inquire endpoint.
        This test submits a Prior Authorization Inquiry request to the server and verifies that a
        response is returned with HTTP status 2XX.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@5', 'hl7.fhir.us.davinci-pas_2.0.1@111', 
                            'hl7.fhir.us.davinci-pas_2.0.1@208'

      input :pa_inquire_request_payload,
            title: 'PAS Inquire Request Payload',
            description: 'Insert Bundle to be sent for PAS Inquire Request',
            type: 'textarea',
            optional: true
      input_order :server_endpoint, :smart_credentials
      
      makes_request :pa_inquire

      def scratch_resources
        scratch[:inquire_request_response_pair] ||= {}
      end

      def request_bundles
        parsed_payload = JSON.parse(pa_inquire_request_payload)
        [parsed_payload].flatten.compact.uniq
      end

      def perform_operation(request_payload)
        
        fhir_operation('/Claim/$inquire', body: request_payload, name: :pa_inquire)
        
        assert_response_status([200, 201])
        assert_valid_json(request.response_body)

        # Save request/response pair
        scratch_resources[:all] ||= []
        scratch_resources[:all] << {request_bundle: request.request_body, response_bundle: resource}
        
      end

      run do
        skip_if pa_inquire_request_payload.blank?, 'No bundle request provided to perform the inquire operation'
        assert_valid_json(pa_inquire_request_payload)

        request_bundles.each do |bundle|
          perform_operation(bundle)
        end
      end
    end
  end
end
