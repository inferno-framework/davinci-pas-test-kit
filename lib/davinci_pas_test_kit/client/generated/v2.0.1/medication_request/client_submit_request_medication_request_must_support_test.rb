require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestMedicationRequestMustSupportTest < DaVinciPASTestKit::MustSupportTest

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

      config(
        options: {
          resource_type: 'MedicationRequest',
          profile_key: 'medication_request',
          user_input_validation: false,
          version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
