require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../user_input_response'
require_relative '../../response_generator'
require_relative '../../client_bundle_validation_helper'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PasClientResponseBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include UserInputResponse
      include ResponseGenerator
      include DaVinciPASTestKit::ClientBundleValidationHelper

      id :pas_client_v221_response_bundle_validation_test
      title '$submit response Bundles have the correct structure and content'
      description %(
        This test verifies the conformity of the submit response sent by Inferno, which will have been
        either:
        - the response body provided by the tester in the corresponding input, or
        - created by Inferno from the $submit Bundle.

        In either case, this test verifies the conformity of the response body to the
        [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-pas-response-bundle.html)
        structure. It also checks that other conformance requirements defined in the [PAS Formal
        Specification](https://hl7.org/fhir/us/davinci-pas/2.2.1/specification.html),
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
      simulation_verification

      def operation_name
        'submit'
      end

      def message_direction_name
        'response'
      end

      def ig_version
        '2.2.1'
      end

      def target_user_input
        case workflow_tag
        when APPROVAL_WORKFLOW_TAG
          :approval_json_response
        when DENIAL_WORKFLOW_TAG
          :denial_json_response
        when PENDED_WORKFLOW_TAG
          :pended_json_response
        when MODIFICATION_WORKFLOW_TAG
          :modification_json_response
        when MUST_SUPPORT_WORKFLOW_TAG
          :ms_submit_responses
        end
      end

      def failed_entities_description
        if user_inputted_response? target_user_input
          "built from tester-provided response in '#{input_title(target_user_input)}'"
        else
          'generated from the submitted claim'
        end
      end

      run do
        failed = non_conformant_bundles
        skip_if failed.present?,
                "Non-conformant response Bundles #{failed_entities_description}: #{failed.join(', ')}. " \
                'Check messages for issues found.'
      end
    end
  end
end
