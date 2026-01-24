require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitResponseRequestorMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Requestor Organization are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Requestor Organization Profile.
        This test checks all identified instances of the PAS Requestor Organization
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Organization.active
        * Organization.address
        * Organization.address.city
        * Organization.address.country
        * Organization.address.line
        * Organization.address.postalCode
        * Organization.address.state
        * Organization.contact
        * Organization.contact.name
        * Organization.contact.telecom
        * Organization.identifier
        * Organization.identifier:NPI
        * Organization.identifier:TIN
        * Organization.name
        * Organization.telecom
        * Organization.type
      )

      id :pas_server_submit_response_v201_requestor_must_support_test

      config(
        options: {
          resource_type: 'Organization',
          profile_key: 'requestor',
          user_input_validation: false,
          version: 'v2.0.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end
