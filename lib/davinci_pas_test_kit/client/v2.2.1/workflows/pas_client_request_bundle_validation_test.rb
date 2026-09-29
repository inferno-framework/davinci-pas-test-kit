require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../client_bundle_validation_helper'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PasClientRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include DaVinciPASTestKit::ClientBundleValidationHelper

      id :pas_client_v221_request_bundle_validation_test
      title '$submit request Bundles have the correct structure and content'
      description %(
        This test verifies the conformity of the client's submit request body to the
        [PAS Request Bundle](http://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-pas-request-bundle.html)
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
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-1'

      def operation_name
        'submit'
      end

      def message_direction_name
        'request'
      end

      def ig_version
        '2.2.1'
      end

      run do
        failed = non_conformant_bundles
        assert failed.empty?,
               "Non-conformant request Bundles detected: #{failed.join(', ')}. Check messages for issues found."
      end
    end
  end
end
