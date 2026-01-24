require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestSubscriberMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Subscriber Patient are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Subscriber Patient Profile.
        This test checks all identified instances of the PAS Subscriber Patient
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * Patient.address
        * Patient.address.city
        * Patient.address.country
        * Patient.address.district
        * Patient.address.line
        * Patient.address.period
        * Patient.address.postalCode
        * Patient.address.state
        * Patient.birthDate
        * Patient.communication
        * Patient.communication.language
        * Patient.extension:birthsex
        * Patient.extension:ethnicity
        * Patient.extension:race
        * Patient.gender
        * Patient.identifier
        * Patient.identifier.system
        * Patient.identifier.value
        * Patient.name
        * Patient.name.family
        * Patient.name.given
        * Patient.name.prefix
        * Patient.name.suffix
        * Patient.telecom
        * Patient.telecom.system
        * Patient.telecom.use
        * Patient.telecom.value
      )

      id :pas_client_submit_request_v201_subscriber_must_support_test

      config(
        options: {
          resource_type: 'Patient',
          profile_key: 'subscriber',
          user_input_validation: false,
          version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
