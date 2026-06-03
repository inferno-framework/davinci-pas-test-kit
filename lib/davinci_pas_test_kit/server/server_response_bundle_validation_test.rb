require_relative '../cross_suite/pas_bundle_validation'
require_relative '../cross_suite/tags'

module DaVinciPASTestKit
  class ServerResponseBundleValidationTest < Inferno::Test
    include DaVinciPASTestKit::PasBundleValidation

    id :pas_server_response_bundle_validation_test
    title 'PAS Bundle is valid'

    input_order :server_endpoint, :smart_credentials

    def operation
      config.options[:operation]
    end

    def ig_version
      config.options[:ig_version]
    end

    def use_case
      config.options[:use_case]
    end

    def response_bundles
      requests = load_tagged_requests(DaVinciPASTestKit.operation_tag(operation),
                                      DaVinciPASTestKit.use_case_tag(use_case))
      bundles = []
      requests.map(&:response_body).compact.uniq.each do |response_body|
        resource = FHIR.from_contents(response_body)
        next unless resource.present?

        # Handle Parameters resource (v2.2.1 inquire responses)
        if resource.resourceType == 'Parameters'
          # Extract all Bundles from Parameters.parameter entries
          parameter_bundles = extract_bundles_from_pas_inquiry_response_parameters(resource)
          bundles.concat(parameter_bundles)
        elsif resource.is_a?(FHIR::Bundle)
          # Handle Bundle resource (v2.0.1 or v2.2.1 non-inquire)
          bundles << resource
        end
      rescue StandardError
        next
      end

      bundles
    end

    run do
      bundles_to_verify = response_bundles
      assert bundles_to_verify.present?,
             "No successful $#{operation} requests made during the #{use_case.titleize} workflow tests."

      bundles_to_verify.each do |bundle|
        perform_bundle_validation(
          bundle,
          operation,
          'response',
          ig_version
        )
      end

      validation_error_messages.each do |msg|
        messages << { type: 'error', message: msg }
      end
      assert validation_error_messages.blank?,
             'Bundle response(s) returned are not conformant. Check messages for issues found.'
    end
  end
end
