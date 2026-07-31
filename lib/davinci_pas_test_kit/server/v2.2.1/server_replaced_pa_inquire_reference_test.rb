require_relative '../../parameters_helper'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASServerReplacedPAInquireReferenceTest < Inferno::Test
      include ParametersHelper

      AUTHORIZATION_NUMBER_EXTENSION =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizationNumber'.freeze
      ADMINISTRATION_REFERENCE_NUMBER_EXTENSION =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-administrationReferenceNumber'.freeze
      REFERENCE_EXTENSION_URLS = [
        AUTHORIZATION_NUMBER_EXTENSION,
        ADMINISTRATION_REFERENCE_NUMBER_EXTENSION
      ].freeze

      id :pas_server_v221_replaced_pa_inquire_reference_test
      title 'Server returns a different reference number for a replaced prior authorization'
      description %(
        This test submits a tester provided Request Bundle containing a
        reference number. The request should result in a response that returns a
        different reference number, indicating that the original prior authorization
        has been replaced.
      )

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-47'

      makes_request :replaced_pa_inquire_request

      input :replaced_pa_inquire_request_body,
            title: 'Inquiry request body for a replaced prior authorization',
            type: 'textarea',
            description: %(
              Provide a PAS Inquiry Request Bundle containing an authorization
              number or administration reference number that is no longer current.
              The server must be configured to return the current authorization
              response with a different corresponding reference number.
            )

      run do
        request_payload = JSON.parse(replaced_pa_inquire_request_body)
        request_payload = request_payload.first if request_payload.is_a?(Array)
        request_resource = FHIR.from_contents(request_payload.to_json)

        assert request_resource.is_a?(FHIR::Bundle),
               'The inquiry request body was not a FHIR Bundle.'

        submitted_references = extract_references(request_resource)

        assert submitted_references.values.flatten.present?,
               'The inquiry request did not contain an authorization number or ' \
               'administration reference number.'

        fhir_operation(
          '/Claim/$inquire',
          body: request_resource,
          name: :replaced_pa_inquire_request
        )

        assert_response_status(200)

        assert resource.is_a?(FHIR::Parameters),
               'The $inquire response was not a FHIR Parameters resource.'

        response_bundles =
          extract_bundles_from_pas_inquiry_response_parameters(resource)

        assert response_bundles.any?,
               'The $inquire response did not contain a response Bundle.'

        returned_references = extract_references(response_bundles)

        assert different_reference?(submitted_references, returned_references),
               'Expected the inquiry response to contain a different authorization number or ' \
               'administration reference number, but it did not.'
      end

      def extract_references(bundles)
        references = Hash.new { |hash, url| hash[url] = [] }

        Array(bundles).each do |bundle|
          next unless bundle.is_a?(FHIR::Bundle)

          Array(bundle.entry).each do |entry|
            resource = entry.resource
            next unless resource.respond_to?(:item)

            Array(resource.item).each do |item|
              Array(item.extension).each do |extension|
                next unless REFERENCE_EXTENSION_URLS.include?(extension.url)
                next if extension.valueString.blank?

                references[extension.url] << extension.valueString
              end
            end
          end
        end

        references
      end

      def different_reference?(submitted, returned)
        REFERENCE_EXTENSION_URLS.any? do |extension_url|
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
