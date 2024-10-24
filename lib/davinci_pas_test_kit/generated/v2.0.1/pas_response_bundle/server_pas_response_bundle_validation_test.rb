require_relative '../../../pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerPasResponseBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation

      id :pas_server_v201_pas_response_bundle_validation_test
      title 'Response Bundle is valid'
      description %(
        This test validates the conformity of the
        server's response to the
        [PAS Response Bundle](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle) structure.
        
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
      
      output :dar_code_found, :dar_extension_found

      def resource_type
        'Bundle'
      end

      def scratch_resources
        scratch[:submit_response_resources] ||= {}
      end

      def request_type
        'submit'
      end
      
      def target_request_response_pairs
        scratch[:submit_request_response_pair] ||= {}
        scratch[:submit_request_response_pair][:all] ||= []
      end

      

      run do
        skip_if target_request_response_pairs.blank?, 'No submit response to validate. Either no submit request was made in a previous test or it resulted in a server error.'
        target_pairs = target_request_response_pairs
        # Clean request/response pair after validatation
        scratch[:submit_request_response_pair][:all] = []

        response_bundles = target_pairs.map { |pair| pair[:response_bundle] }
        save_bundles_and_entries_to_scratch(response_bundles)

        target_pairs.each do |pair|
          pair => {request_bundle:, response_bundle:}
          assert_resource_type(:bundle, resource: response_bundle)

          perform_response_validation(
            response_bundle,
            'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle',
            '2.0.1',
            request_type,
            request_bundle
          )
        end

        validation_error_messages.each do |msg|
          messages << { type: 'error', message: msg }
        end
        msg = 'Bundle response returned and/or entry resources are not conformant. Check messages for issues found.'
        assert validation_error_messages.blank?, msg
      end
    end
  end
end
