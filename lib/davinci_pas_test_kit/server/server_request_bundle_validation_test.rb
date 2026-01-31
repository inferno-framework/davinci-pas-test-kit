require_relative '../cross_suite/pas_bundle_validation'

module DaVinciPASTestKit
  class ServerRequestBundleValidationTest < Inferno::Test
    include DaVinciPASTestKit::PasBundleValidation

    id :pas_server_request_bundle_validation_test
    title 'PAS Request Bundle is conformant'

    input :bundle_payload,
          type: 'textarea',
          optional: true

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

    def bundles
      parsed_payload = JSON.parse(bundle_payload)
      fhir_resources =
        [parsed_payload].flatten.compact.uniq.map do |payload|
          FHIR.from_contents(payload.to_json)
        rescue StandardError
          nil
        end.compact
      fhir_resources.select { |res| res.resourceType == 'Bundle' }
    end

    run do
      skip_if bundle_payload.blank?, 'No bundle request input provided.'
      assert_valid_json(bundle_payload,
                        "Provide valid json to use for the $#{operation} during the #{use_case.titleize} workflow.")
      bundles_to_verify = bundles

      assert bundles_to_verify.present?, 'Provided input is not a Bundle or list of Bundles.'

      bundles_to_verify.each do |bundle|
        perform_bundle_validation(
          bundle,
          operation,
          'request',
          ig_version
        )
      end

      validation_error_messages.each do |msg|
        messages << { type: 'error', message: msg }
      end

      skip_if validation_error_messages.present?,
              'Bundle(s) provided are not conformant. Check messages for issues found.'
    end
  end
end
