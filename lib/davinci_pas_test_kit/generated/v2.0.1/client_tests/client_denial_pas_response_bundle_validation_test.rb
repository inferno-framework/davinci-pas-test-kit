require_relative '../../../pas_bundle_validation'
require_relative '../../../user_input_response'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientDenialPasResponseBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include UserInputResponse

      id :pas_client_v201_denial_pas_response_bundle_validation_test
      title '[USER INPUT VALIDATION] Response Bundle is valid'
      description %(
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
        Errors encountered will be treated as a skip instead of a failure.
        
        This test validates the conformity of the
        user input to the
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
      )

      def resource_type
        'Bundle'
      end

      def request_type
        'submit'
      end

      run do
        check_user_inputted_response :denial_json_response
        validate_pas_bundle_json(
          denial_json_response,
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle',
          '2.0.1',
          request_type,
          'response_bundle',
          skips: true,
          message: "Invalid input for '#{input_title(:denial_json_response)}':"
        )
      end
    end
  end
end
