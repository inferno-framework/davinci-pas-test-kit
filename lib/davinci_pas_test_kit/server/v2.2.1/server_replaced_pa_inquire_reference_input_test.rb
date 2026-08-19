require_relative '../../cross_suite/pas_constants'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASServerReplacedPAInquireReferenceInputTest < Inferno::Test
      include PASConstants

      id :pas_server_v221_replaced_pa_inquire_reference_input_test
      title 'Provided $inquire Request contains a replaced prior authorization reference'
      description %(
        Provide one or more PAS Inquiry Request Bundles, at least one of which contains
        an authorization number or administration reference number.
      )

      simulation_verification

      input :must_support_pa_inquire_request_payload,
            title: 'Additional $inquire Request Payloads',
            description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'

      run do
        skip_if must_support_pa_inquire_request_payload.blank?,
                'No inquiry request body was provided.'

        assert_valid_json(
          must_support_pa_inquire_request_payload,
          'Provide a valid JSON PAS Inquiry Request Bundle.'
        )

        parsed_payload = JSON.parse(must_support_pa_inquire_request_payload)
        request_payloads = Array.wrap(parsed_payload)

        assert request_payloads.present?,
               'No inquiry Request Bundles were provided.'

        request_bundles = request_payloads.map do |request_payload|
          FHIR.from_contents(request_payload.to_json)
        end

        assert request_bundles.all?(FHIR::Bundle),
               'Each inquiry request body must be a FHIR Bundle.'

        assert request_bundles.any? { |request_bundle| reference_numbers(request_bundle).present? },
               'The inquiry requests did not contain an authorization number or ' \
               'administration reference number.'
      end

      def reference_numbers(bundle)
        bundle.entry.flat_map do |entry|
          resource = entry.resource
          next [] unless resource.respond_to?(:item)

          resource.item.flat_map do |item|
            item.extension.filter_map do |extension|
              extension.valueString if REFERENCE_NUMBER_EXTENSIONS.value?(extension.url) &&
                                       extension.valueString.present?
            end
          end
        end
      end
    end
  end
end
