require_relative '../../../pas_bundle_validation'
require_relative '../../../user_input_response'
require_relative '../../../response_generator'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClientResponseBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include UserInputResponse
      include ResponseGenerator

      id :pas_client_v201_response_bundle_validation_test
      title '[USER INPUT VERIFICATION] Submit Response Bundle is valid'
      description %(
        **USER INPUT VERIFICATION**: This test verifies input provided by the tester instead of the system under test.
        Errors encountered will be treated as a skip instead of a failure.

        This test verifies the conformity of the submit response sent by Inferno, which will have been
        either:
        - the response body provided by the tester in the corresponding input, or
        - created by Inferno from the $submit Bundle.

        In either case, this test verifies the conformity of the response body to the
        [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-response-bundle.html)
        structure. It also checks that other conformance requirements defined in the [PAS Formal
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

      def request_type
        'submit'
      end

      def workflow_tag
        config.options[:workflow_tag]
      end

      def target_user_input
        case workflow_tag
        when APPROVAL_WORKFLOW_TAG
          :approval_json_response
        when DENIAL_WORKFLOW_TAG
          :denial_json_response
        when PENDED_WORKFLOW_TAG
          :pended_json_response
        end
      end

      run do
        load_tagged_requests(workflow_tag, SUBMIT_TAG)
        skip_if requests.empty?, 'No responses to verify because no submit requests were made.'
        message = if user_inputted_response? target_user_input
                    "Invalid response generated from provided input '#{input_title(target_user_input)}':"
                  else
                    'Invalid response generated from the submitted claim:'
                  end

        validate_pas_bundle_json(
          request.response_body,
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle',
          '2.0.1',
          request_type,
          'response_bundle',
          skips: true,
          message:
        )
      end
    end
  end
end
