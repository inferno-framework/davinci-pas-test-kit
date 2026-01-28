require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireResponseMustSupportPractitionerTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v201_inquire_response_must_support_practitioner
      title 'All must support elements for Profile PAS Practitioner are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Practitioner Profile.
        This test checks all identified instances of the PAS Practitioner
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Practitioner.address
        * Practitioner.identifier
        * Practitioner.identifier:NPI
        * Practitioner.name
        * Practitioner.name.family
        * Practitioner.telecom
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@38'

      config(
        options: {
          resource_type: 'Practitioner',
          profile_key: 'practitioner',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
