require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ClientInquireResponseMustSupportPractitionerTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v220_inquire_response_must_support_practitioner
      title 'All must support elements for Profile PAS Practitioner are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Practitioner Profile.
        This test checks all identified instances of the PAS Practitioner
        Profile on responses sent to the client to ensure that the following
        must support elements are observed:

        * Practitioner.address
        * Practitioner.address.city
        * Practitioner.address.country
        * Practitioner.address.line
        * Practitioner.address.postalCode
        * Practitioner.address.state
        * Practitioner.identifier
        * Practitioner.identifier:NPI
        * Practitioner.name
        * Practitioner.name.family
        * Practitioner.telecom
        * Practitioner.telecom.system
        * Practitioner.telecom.value
      )

      config(
        options: {
          resource_type: 'Practitioner',
          profile_key: 'practitioner',
          user_input_validation: true,
          ig_version: 'v2.2.0',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end