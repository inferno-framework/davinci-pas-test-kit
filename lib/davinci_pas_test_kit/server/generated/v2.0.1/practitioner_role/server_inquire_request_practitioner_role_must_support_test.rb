require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireRequestPractitionerRoleMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS PractitionerRole are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS PractitionerRole Profile.
        This test checks all identified instances of the PAS PractitionerRole
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * PractitionerRole.organization
        * PractitionerRole.practitioner
      )

      id :pas_server_inquire_request_v201_practitioner_role_must_support_test

      config(
        options: {
          resource_type: 'PractitionerRole',
          profile_key: 'practitioner_role',
          user_input_validation: true,
          version: 'v2.0.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
