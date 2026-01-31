require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestMustSupportEncounterTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v201_submit_request_must_support_encounter
      title 'All must support elements for Profile PAS Encounter are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Encounter Profile.
        This test checks all identified instances of the PAS Encounter
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * Encounter.class
        * Encounter.extension:nursingHomeResidentialStatus
        * Encounter.extension:patientStatus
        * Encounter.hospitalization
        * Encounter.hospitalization.admitSource
        * Encounter.hospitalization.dischargeDisposition
        * Encounter.identifier
        * Encounter.identifier.system
        * Encounter.identifier.value
        * Encounter.location
        * Encounter.location.location
        * Encounter.participant
        * Encounter.participant.individual
        * Encounter.participant.period
        * Encounter.participant.type
        * Encounter.period
        * Encounter.reasonCode
        * Encounter.status
        * Encounter.subject
        * Encounter.type
      )

      config(
        options: {
          resource_type: 'Encounter',
          profile_key: 'encounter',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
