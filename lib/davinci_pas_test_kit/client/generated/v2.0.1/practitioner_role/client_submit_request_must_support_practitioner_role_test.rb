require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestMustSupportPractitionerRoleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v201_submit_request_must_support_practitioner_role
      title 'All must support elements for Profile PAS PractitionerRole are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS PractitionerRole Profile.
        This test checks all identified instances of the PAS PractitionerRole
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * PractitionerRole.organization
        * PractitionerRole.practitioner
      )

      config(
        options: {
          resource_type: 'PractitionerRole',
          profile_key: 'practitioner_role',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
