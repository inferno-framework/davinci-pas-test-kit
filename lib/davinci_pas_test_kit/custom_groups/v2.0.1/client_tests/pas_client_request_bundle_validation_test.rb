require_relative '../../../pas_bundle_validation'
require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClientRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation
      include URLs

      id :pas_client_v201_request_bundle_validation_test
      title 'Submit Request Bundle is valid'
      description %(
        This test verifies the conformity of the client's submit request body to the
        [PAS Request Bundle](http://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-request-bundle.html)
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
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@58', 'hl7.fhir.us.davinci-pas_2.0.1@59',
                            'hl7.fhir.us.davinci-pas_2.0.1@60', 'hl7.fhir.us.davinci-pas_2.0.1@74',
                            'hl7.fhir.us.davinci-pas_2.0.1@75', 'hl7.fhir.us.davinci-pas_2.0.1@76',
                            'hl7.fhir.us.davinci-pas_2.0.1@77', 'hl7.fhir.us.davinci-pas_2.0.1@78',
                            'hl7.fhir.us.davinci-pas_2.0.1@81', 'hl7.fhir.us.davinci-pas_2.0.1@85',
                            'hl7.fhir.us.davinci-pas_2.0.1@86'

      def workflow_tag
        config.options[:workflow_tag]
      end

      def request_type_tag
        SUBMIT_TAG
      end

      run do
        if workflow_tag.present?
          load_tagged_requests(request_type_tag, workflow_tag)
        else
          load_tagged_requests(request_type_tag)
        end
        skip_if !request.present?, 'No submit requests received.'

        validate_pas_bundle_json(
          request.request_body,
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
          '2.0.1',
          'submit',
          'request_bundle',
          message: 'The Bundle provided for the Claim/$submit operation is invalid:'
        )
      end
    end
  end
end
