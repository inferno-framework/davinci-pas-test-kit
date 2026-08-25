require_relative '../../parameters_helper'
require_relative '../../cross_suite/pas_constants'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASServerReplacedPAInquireReferenceTest < Inferno::Test
      include ParametersHelper
      include PASConstants

      id :pas_server_v221_replaced_pa_inquire_reference_test
      title 'Server returns a different reference number for a replaced prior authorization'
      description %(
        This test submits a tester provided Request Bundle containing a
        reference number. The request should result in a response that returns a
        different reference number, indicating that the original prior authorization
        has been replaced.
      )

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-47'

      makes_request :pa_inquire_request

      input :must_support_pa_inquire_request_payload,
            title: 'Additional $inquire Request Payloads',
            description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'

      run do
        assert_valid_json(
          must_support_pa_inquire_request_payload,
          'Provide a valid JSON PAS Inquiry Request Bundle.'
        )
        parsed_payload = JSON.parse(must_support_pa_inquire_request_payload)
        request_payloads = Array.wrap(parsed_payload)

        reference_comparisons = request_payloads.map do |request_payload|
          request_resource = FHIR.from_contents(request_payload.to_json)

          submitted_references = extract_references([request_resource])

          fhir_operation(
            '/Claim/$inquire',
            body: request_resource,
            name: :pa_inquire_request
          )

          assert_response_status(200)

          response_bundles =
            if resource.is_a?(FHIR::Parameters)
              extract_bundles_from_pas_inquiry_response_parameters(resource)
            elsif resource.is_a?(FHIR::Bundle)
              [resource]
            else
              assert false, '$inquire response is neither Parameters or Bundle'
            end

          assert response_bundles.any?,
                 'The $inquire response did not contain a response Bundle.'

          returned_references = extract_references(response_bundles)

          different_reference?(submitted_references, returned_references)
        end

        assert reference_comparisons.any?,
               'Expected an inquiry response to contain a different authorization number or ' \
               'administration reference number, but it did not.'
      end

      def extract_references(bundles)
        bundles.each_with_object(
          Hash.new { |hash, url| hash[url] = [] }
        ) do |bundle, references|
          next unless bundle.is_a?(FHIR::Bundle)

          bundle.entry.each do |entry|
            resource = entry.resource
            next unless resource.respond_to?(:item)

            resource.item.each do |item|
              item.extension.each do |extension|
                next unless REFERENCE_NUMBER_EXTENSIONS.value?(extension.url)
                next if extension.valueString.blank?

                references[extension.url] << extension.valueString
              end
            end
          end
        end
      end

      def different_reference?(submitted, returned)
        REFERENCE_NUMBER_EXTENSIONS.each_value.any? do |extension_url|
          submitted_values = submitted[extension_url]
          returned_values = returned[extension_url]

          next false if submitted_values.empty? || returned_values.empty?

          returned_values.any? do |returned_value|
            submitted_values.exclude?(returned_value)
          end
        end
      end
    end
  end
end
