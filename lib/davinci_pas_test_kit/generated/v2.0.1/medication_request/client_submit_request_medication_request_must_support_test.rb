require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestMedicationRequestMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Medication Request are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Medication Request Profile.
        This test checks all identified instances of the PAS Medication Request
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * MedicationRequest.authoredOn
        * MedicationRequest.dispenseRequest
        * MedicationRequest.dispenseRequest.quantity
        * MedicationRequest.dosageInstruction
        * MedicationRequest.dosageInstruction.text
        * MedicationRequest.dosageInstruction.timing
        * MedicationRequest.encounter
        * MedicationRequest.extension:coverage
        * MedicationRequest.intent
        * MedicationRequest.medication[x]
        * MedicationRequest.reported[x]
        * MedicationRequest.requester
        * MedicationRequest.status
        * MedicationRequest.subject
      )

      id :pas_client_submit_request_v201_medication_request_must_support_test

      def resource_type
        'MedicationRequest'
      end

      def user_input_validation
        false
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        # The scratch key in MS test should be the same as the scratch key in the validation test for a given profile.
        scratch[:submit_request_resources] ||= {}
      end

      def resources_of_interest
        collection = tagged_resources(SUBMIT_TAG).presence || all_scratch_resources
        collection.select { |res| res.resourceType == resource_type }
      end

      run do
        perform_must_support_test(resources_of_interest)
        validate_must_support(user_input_validation)
      end
    end
  end
end
