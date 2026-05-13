require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ServerInquireRequestMustSupportPractitionerRoleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v220_inquire_request_must_support_practitioner_role
      title 'All must support elements for Profile PAS PractitionerRole are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS PractitionerRole Profile.
        This test checks all identified instances of the PAS PractitionerRole
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * PractitionerRole.code
        * PractitionerRole.endpoint
        * PractitionerRole.location
        * PractitionerRole.organization
        * PractitionerRole.practitioner
        * PractitionerRole.specialty
        * PractitionerRole.telecom
        * PractitionerRole.telecom.system
        * PractitionerRole.telecom.value
      )

      config(
        options: {
          resource_type: 'PractitionerRole',
          profile_key: 'practitioner_role',
          user_input_validation: true,
          ig_version: 'v2.2.0',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
