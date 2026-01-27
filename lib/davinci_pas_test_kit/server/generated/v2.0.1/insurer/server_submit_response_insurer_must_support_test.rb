require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitResponseInsurerMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Insurer Organization are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Insurer Organization Profile.
        This test checks all identified instances of the PAS Insurer Organization
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Organization.active
        * Organization.address
        * Organization.address.city
        * Organization.address.country
        * Organization.address.line
        * Organization.address.postalCode
        * Organization.address.state
        * Organization.identifier
        * Organization.identifier:NPI
        * Organization.identifier:TIN
        * Organization.name
        * Organization.telecom
        * Organization.type
      )

      id :pas_server_submit_response_v201_insurer_must_support_test

      config(
        options: {
          resource_type: 'Organization',
          profile_key: 'insurer',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end
