require_relative '../../../cross_suite/must_support/must_support_request_type_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClientMustSupportRequirementTest < DaVinciPASTestKit::MustSupportRequestTypeTest
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

      config(
        options: {
          profile_keys: ['device_request', 'medication_request', 'nutrition_order', 'service_request'],
          user_input_validation: false,
          version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
