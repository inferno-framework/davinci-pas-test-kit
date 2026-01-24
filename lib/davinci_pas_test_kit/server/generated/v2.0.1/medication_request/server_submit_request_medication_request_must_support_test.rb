require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitRequestMedicationRequestMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Medication Request are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Medication Request Profile.
        This test checks all identified instances of the PAS Medication Request
        Profile on requests sent to the server to ensure that the following
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

      id :pas_server_submit_request_v201_medication_request_must_support_test

      config(
        options: {
          resource_type: 'MedicationRequest',
          profile_key: 'medication_request',
          user_input_validation: true,
          version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
