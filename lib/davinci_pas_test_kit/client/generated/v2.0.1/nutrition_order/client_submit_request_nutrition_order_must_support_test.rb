require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestNutritionOrderMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Nutrition Order are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Nutrition Order Profile.
        This test checks all identified instances of the PAS Nutrition Order
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * NutritionOrder.enteralFormula
        * NutritionOrder.enteralFormula.baseFormulaType
        * NutritionOrder.extension:coverage
        * NutritionOrder.oralDiet
        * NutritionOrder.oralDiet.type
        * NutritionOrder.patient
      )

      id :pas_client_submit_request_v201_nutrition_order_must_support_test

      config(
        options: {
          resource_type: 'NutritionOrder',
          profile_key: 'nutrition_order',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
