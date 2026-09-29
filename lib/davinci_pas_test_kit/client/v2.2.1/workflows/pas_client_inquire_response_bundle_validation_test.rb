require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../user_input_response'
require_relative '../../response_generator'
require_relative '../../client_bundle_validation_helper'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PasClientInquireResponseBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include UserInputResponse
      include ResponseGenerator
      include DaVinciPASTestKit::ClientBundleValidationHelper

      id :pas_client_v221_inquire_response_bundle_validation_test
      title '$inquire response Bundles have the correct structure and content'
      description %(
        This test verifies the conformity of the inquire response sent by Inferno, which will have been
        either:
        - the response body provided by the tester in the corresponding input, or
        - created by Inferno from the $inquire Bundle.

        In either case, this test verifies the conformity of the response body to the
        [PAS Inquiry Response Bundle](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-pas-inquiry-response-bundle.html)
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
        'inquire'
      end

      def message_direction_name
        'response'
      end

      def ig_version
        '2.2.1'
      end

      def target_user_input
        case workflow_tag
        when MUST_SUPPORT_WORKFLOW_TAG
          :ms_inquire_responses
        else
          :inquire_json_response
        end
      end

      # v2.2.1 inquire response is a Parameters with one or more Bundles
      def bundles_from_message_resource(message_resource, message_label)
        case message_resource
        when FHIR::Bundle
          messages << { type: 'error',
                        message: "#{message_label} expected a Parameters resource, got Bundle." }
          [message_resource]

        when FHIR::Parameters
          target_parameter_name = 'return'
          message_resource.parameter.select { |parameter| parameter.name == target_parameter_name }
            .map.with_index do |parameter, parameter_index|
              case parameter.resource
              when FHIR::Bundle
                parameter.resource
              else
                messages << { type: 'error',
                              message: "#{message_label} Parameters resource '#{target_parameter_name}' " \
                                       "entry #{parameter_index + 1} expected to " \
                                       "contain a Bundle, got #{parameter.resource&.resourceType}" }
                nil
              end
            end.compact
        else
          messages << { type: 'error',
                        message: "#{message_label} expected a Parameters resource, " \
                                 "got #{message_resource.resourceType}." }
          []
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
