require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireRequestMustSupportPractitionerTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v201_inquire_request_must_support_practitioner
      title 'All must support elements for Profile PAS Practitioner are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Practitioner Profile.
        This test checks all identified instances of the PAS Practitioner
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * Practitioner.address
        * Practitioner.identifier
        * Practitioner.identifier:NPI
        * Practitioner.name
        * Practitioner.name.family
        * Practitioner.telecom
      )

      config(
        options: {
          resource_type: 'Practitioner',
          profile_key: 'practitioner',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
