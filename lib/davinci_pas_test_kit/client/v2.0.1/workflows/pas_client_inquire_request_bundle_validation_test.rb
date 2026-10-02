require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../client_bundle_validation_helper'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClientInquireRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include DaVinciPASTestKit::ClientBundleValidationHelper

      id :pas_client_v201_inquire_request_bundle_validation_test
      title 'Inquire Request Bundle is valid'
      description %(
        This test verifies the conformity of the client's request body to the
        [PAS Inquiry Request Bundle](http://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-request-bundle.html)
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
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@75', 'hl7.fhir.us.davinci-pas_2.0.1@121',
                            'hl7.fhir.us.davinci-pas_2.0.1@122', 'hl7.fhir.us.davinci-pas_2.0.1@123',
                            'hl7.fhir.us.davinci-pas_2.0.1@125', 'hl7.fhir.us.davinci-pas_2.0.1@126',
                            'hl7.fhir.us.davinci-pas_2.0.1@127', 'hl7.fhir.us.davinci-pas_2.0.1@128'

      def operation_name
        'inquire'
      end

      def message_direction_name
        'request'
      end

      def ig_version
        '2.0.1'
      end

      run do
        failed = non_conformant_bundles
        assert failed.empty?,
               "Non-conformant request Bundles detected: #{failed.join(', ')}. Check messages for issues found."
      end
    end
  end
end
