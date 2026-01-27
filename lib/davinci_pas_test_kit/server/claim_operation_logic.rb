require_relative '../cross_suite/tags'

module DaVinciPASTestKit
  module ClaimOperationLogic
    def operation_tag
      DaVinciPASTestKit.const_get(:"#{operation.upcase}_TAG")
    end

    def use_case
      config.options[:use_case]
    end

    def use_case_tag
      DaVinciPASTestKit.const_get(:"#{use_case.upcase}_WORKFLOW_TAG")
    end

    def request_bundles(request_payload)
      parsed_payload = JSON.parse(request_payload)
      [parsed_payload].flatten.compact
    end

    def perform_operation(request_payload)
      start_time = Time.now
      request = fhir_operation("/Claim/$#{operation}", body: request_payload, tags: [use_case_tag, operation_tag])
      response_time = Time.now - start_time

      if operation == 'submit' && response_time > 15
        warning %(
              The server took more that 15 seconds to respond to the Prior Authorization
              request.

              Response Time: #{response_time}
            )
      end

      request
    end

    def check_response_status_and_payload(request)
      assert_response_status([200, 201])
      assert_valid_json(request.response_body)
      assert_resource_type(:bundle, resource: FHIR.from_contents(request.response_body))
    end

    def run_operation_test(request_payload)
      skip_if request_payload.blank?, "No bundle request provided to perform the #{operation} operation"
      assert_valid_json(request_payload)

      requests_performed = request_bundles(request_payload).map do |bundle|
        perform_operation(bundle)
      end

      requests_performed.each { |request| check_response_status_and_payload(request) }
    end
  end
end
