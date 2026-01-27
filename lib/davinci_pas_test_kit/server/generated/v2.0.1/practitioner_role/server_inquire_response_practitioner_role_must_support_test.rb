require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireResponsePractitionerRoleMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS PractitionerRole are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS PractitionerRole Profile.
        This test checks all identified instances of the PAS PractitionerRole
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * PractitionerRole.organization
        * PractitionerRole.practitioner
      )

      id :pas_server_inquire_response_v201_practitioner_role_must_support_test

      config(
        options: {
          resource_type: 'PractitionerRole',
          profile_key: 'practitioner_role',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
