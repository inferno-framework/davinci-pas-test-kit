require_relative '../../../pas_bundle_validation'
require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientPasRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include URLs

      id :pas_client_v201_pas_request_bundle_validation_test
      title 'Request Bundle is valid'
      description %(
        This test validates the conformity of the
        client's request to the
        [PAS Request Bundle](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle) structure.
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
      )

      def resource_type
        'Bundle'
      end

      def request_type
        'submit'
      end

      run do
        assert request.url == submit_url,
             "Request made to wrong URL: #{request.url}. Should instead be to #{submit_url}"

        validate_pas_bundle_json(
          request.request_body,
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
          '2.0.1',
          request_type,
          'request_bundle',
          message: 'The submit Bundle request provided for the Claim/$submit operation is invalid:'
        )
        
      end
    end
  end
end
