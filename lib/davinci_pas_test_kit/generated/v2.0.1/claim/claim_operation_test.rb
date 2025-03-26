module DaVinciPASTestKit
  module DaVinciPASV201
    class ClaimOperationTest < Inferno::Test

      id :pas_v201_claim_operation_test
      title 'Submission of a claim to the $submit operation succeeds'
      description %(
        Server SHALL support PAS Submit requests: a POST interaction to
        the /Claim/$submit endpoint.
        This test submits a Prior Authorization Submit request to the server and verifies that a
        response is returned with HTTP status 2XX.
        The server SHOULD respond within 15 seconds.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@5', 'hl7.fhir.us.davinci-pas_2.0.1@66',
                            'hl7.fhir.us.davinci-pas_2.0.1@111', 'hl7.fhir.us.davinci-pas_2.0.1@136',
                            'hl7.fhir.us.davinci-pas_2.0.1@207'

      input :pa_submit_request_payload,
            title: 'PAS Submit Request Payload',
            description: 'Insert Bundle to be sent for PAS Submit Request',
            type: 'textarea',
            optional: true
      input_order :server_endpoint, :smart_credentials
      output :response_time
      makes_request :pa_submit

      def scratch_resources
        scratch[:submit_request_response_pair] ||= {}
      end

      def request_bundles
        parsed_payload = JSON.parse(pa_submit_request_payload)
        [parsed_payload].flatten.compact.uniq
      end

      def perform_operation(request_payload)
        start_time = Time.now
        fhir_operation('/Claim/$submit', body: request_payload, name: :pa_submit)
        response_time = Time.now - start_time

        if response_time > 15
          warning %(
              The server took more that 15 seconds to respond to the Prior Authorization
              request.

              Response Time: #{response_time}
            )
        end
        
        assert_response_status([200, 201])
        assert_valid_json(request.response_body)

        # Save request/response pair
        scratch_resources[:all] ||= []
        scratch_resources[:all] << {request_bundle: request.request_body, response_bundle: resource}
        output response_time:
      end

      run do
        skip_if pa_submit_request_payload.blank?, 'No bundle request provided to perform the submit operation'
        assert_valid_json(pa_submit_request_payload)

        request_bundles.each do |bundle|
          perform_operation(bundle)
        end
      end
    end
  end
end
