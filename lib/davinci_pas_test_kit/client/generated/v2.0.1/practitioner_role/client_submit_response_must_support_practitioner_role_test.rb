require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitResponseMustSupportPractitionerRoleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v201_submit_response_must_support_practitioner_role
      title 'All must support elements for Profile PAS PractitionerRole are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS PractitionerRole Profile.
        This test checks all identified instances of the PAS PractitionerRole
        Profile on responses sent to the client to ensure that the following
        must support elements are observed:

        * PractitionerRole.organization
        * PractitionerRole.practitioner
      )

      config(
        options: {
          resource_type: 'PractitionerRole',
          profile_key: 'practitioner_role',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end