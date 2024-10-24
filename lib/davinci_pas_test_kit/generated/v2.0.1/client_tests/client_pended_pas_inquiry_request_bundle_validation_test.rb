require_relative '../../../pas_bundle_validation'
require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientPendedPasInquiryRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include URLs

      id :pas_client_v201_pended_pas_inquiry_request_bundle_validation_test
      title 'Inquiry Request Bundle is valid'
      description %(
        This test validates the conformity of the
        client's request to the
        [PAS Inquiry Request Bundle](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle) structure.
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

      def resource_type
        'Bundle'
      end

      def request_type
        'inquire'
      end

      run do
        assert request.url == inquire_url,
             "Request made to wrong URL: #{request.url}. Should instead be to #{inquire_url}"

        validate_pas_bundle_json(
          request.request_body,
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle',
          '2.0.1',
          request_type,
          'request_bundle',
          message: 'The inquire Bundle request provided for the Claim/$inquire operation is invalid:'
        )
        
      end
    end
  end
end
