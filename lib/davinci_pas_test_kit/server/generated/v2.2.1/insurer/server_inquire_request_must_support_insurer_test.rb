require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ServerInquireRequestMustSupportInsurerTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v221_inquire_request_must_support_insurer
      title 'All must support elements for Profile PAS Insurer Organization are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Insurer Organization Profile.
        This test checks all identified instances of the PAS Insurer Organization
        Profile on requests sent to the server to ensure that the following
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
        * Organization.identifier:PI
        * Organization.identifier:TIN
        * Organization.name
        * Organization.telecom
        * Organization.telecom.system
        * Organization.telecom.value
        * Organization.type
      )

      config(
        options: {
          resource_type: 'Organization',
          profile_key: 'insurer',
          user_input_validation: true,
          ig_version: 'v2.2.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
