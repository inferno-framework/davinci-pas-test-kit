require_relative '../../../cross_suite/pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PasClientRequestBundleValidationTest < Inferno::Test
      include DaVinciPASTestKit::PasBundleValidation

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
          '2.2.1',
          'submit',
          'request_bundle',
          message: 'The Bundle provided for the Claim/$submit operation is invalid:'
        )
      end
    end
  end
end
