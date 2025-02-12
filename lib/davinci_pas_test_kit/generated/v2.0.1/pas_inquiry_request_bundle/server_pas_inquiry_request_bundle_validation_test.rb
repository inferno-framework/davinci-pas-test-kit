require_relative '../../../pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerPasInquiryRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation

      id :pas_server_v201_pas_inquiry_request_bundle_validation_test
      title '[USER INPUT VALIDATION] Inquiry Request Bundle is valid'
      description %(
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
        Errors encountered will be treated as a skip instead of a failure.
        
        
        This test validates the conformity of the
        user input to the
        [PAS Inquiry Request Bundle](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle) 
        structure, ensuring subsequent tests can accurately simulate content.
        
        It also checks that other conformance requirements defined in the [PAS Formal
        Specification](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html),
        such as the presence of all referenced instances within the bundle and the
        conformance of those instances to the appropriate profiles, are met.
        
        It verifies the presence of mandatory elements and that elements with
        required bindings contain appropriate values. CodeableConcept element
        bindings will fail if none of their codings have a code/system belonging
        to the bound ValueSet. Quantity, Coding, and code element bindings will
        fail if their code/system are not found in the valueset.
        
        Note that because X12 value sets are not public, elements bound to value
        sets containing X12 codes are not validated.
        
        **Limitations**
        
        Due to recognized errors in the PAS IG around extension context definitions,
        this test may not pass due to spurious errors of the form "The extension
        [extension url] is not allowed at this point". See [this
        issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues/11)
        for additional details.
      )
      
      input :pa_inquire_request_payload,
            title: 'PAS Inquire Request Payload',
            description: 'Insert Bundle to be sent for PAS Inquire Request',
            type: 'textarea',
            optional: true

      input_order :server_endpoint, :smart_credentials
      output :dar_code_found, :dar_extension_found

      def resource_type
        'Bundle'
      end

      def scratch_resources
        scratch[:inquire_request_resources] ||= {}
      end

      def request_type
        'inquire'
      end
      

      
      def request_bundles
        parsed_payload = JSON.parse(pa_inquire_request_payload)
        fhir_resources = [parsed_payload].flatten.compact.uniq.map { |payload| FHIR.from_contents(payload.to_json)}.compact
        fhir_resources.select { |res| res.resourceType == 'Bundle'}
      end

      run do
        skip_if pa_inquire_request_payload.blank?, 'No bundle request input provided.'
        assert_valid_json(pa_inquire_request_payload)
        assert request_bundles.present?, 'Provided input is not a bundle or list of bundles'

        save_bundles_and_entries_to_scratch(request_bundles)

        request_bundles.each do |bundle|
          perform_request_validation(
            bundle,
            'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle',
            '2.0.1',
            request_type
          )
        end

        validation_error_messages.each do |msg|
          messages << { type: 'error', message: msg }
        end
        msg = 'Bundle(s) provided and/or entry resources are not conformant. Check messages for issues found.'
        skip_if validation_error_messages.present?, msg
      
      end
    end
  end
end
