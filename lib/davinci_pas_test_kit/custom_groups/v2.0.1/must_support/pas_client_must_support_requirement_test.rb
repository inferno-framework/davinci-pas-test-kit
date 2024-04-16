require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClientMustSupportRequirementTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      attr_accessor :resource_type

      id :pas_client_submit_v201_must_support_requirement
      title %(
        At least one instance of a request profile (PAS Medication Request, PAS Service Request,
        PAS Device Request, or PAS Nutrition Order) is observed with all of its must support elements
      )
      description %(
        The PAS IG includes four profiles for providing the specifics of the service or product requested
        in the prior authorization request. Any one of these profiles can be referenced in
        the must support element `Claim.item.extension:requestedService`:

        * PAS Medication Request
        * PAS Service Request
        * PAS Device Request
        * PAS Nutrition Order

        System are allowed to support only the request profiles that fit their use cases. However,
        they must support at least one of them (because `Claim.item.extension:requestedService` is a
        must support element) and for any request profiles they support, they must be able to
        populate all of the defined must support elements.

        This test ensures that the submitted request bundles include at least one instance of a
        profile listed above. Then for each profile observed, it checks for the presence of
        each must support element defined in that profile.

        The test will look through the instances included in submissions made by the client
        for the following must support elements:

        ### PAS Medication Request
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

        ### PAS Service Request
        * ServiceRequest.code
        * ServiceRequest.extension:coverage
        * ServiceRequest.extension:serviceCodeEnd
        * ServiceRequest.occurrence[x]
        * ServiceRequest.quantity[x]
        * ServiceRequest.subject

        ### PAS Device Request
        * DeviceRequest.code[x]
        * DeviceRequest.extension:coverage
        * DeviceRequest.occurrence[x]
        * DeviceRequest.subject

        ### PAS Nutrition Order
        * NutritionOrder.enteralFormula
        * NutritionOrder.enteralFormula.baseFormulaType
        * NutritionOrder.extension:coverage
        * NutritionOrder.oralDiet
        * NutritionOrder.oralDiet.type
        * NutritionOrder.patient
      )

      def resource_types
        ['DeviceRequest', 'MedicationRequest', 'NutritionOrder', 'ServiceRequest']
      end

      def self.metadata
        metadata_file_name = "#{@@resource_type.underscore}_metadata.yml"
        Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, metadata_file_name),
                                                    aliases: true))
      end

      def scratch_resources
        scratch[:submit_request_resources] ||= {}
      end

      def all_scratch_resources
        scratch_resources[:all] ||= []
      end

      def resources_of_interest
        collection = tagged_resources(SUBMIT_TAG).presence || all_scratch_resources
        collection.select { |resource| resource_types.include?(resource.resourceType) }
      end

      def grouped_resources
        resources_of_interest.group_by(&:resourceType)
      end

      run do
        msg = 'Request Bundle must include at least one instance of either DeviceRequest, MedicationRequest,
                NutritionOrder, or ServiceRequest resource'
        assert resources_of_interest.present?, msg

        grouped_resources.each do |type, resources|
          @@resource_type = @resource_type = type # rubocop:disable Style/ClassVars
          perform_must_support_test(resources)
        end
        validate_must_support
      end
    end
  end
end
