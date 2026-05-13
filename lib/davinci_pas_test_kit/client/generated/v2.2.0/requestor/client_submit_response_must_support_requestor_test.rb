require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ClientSubmitResponseMustSupportRequestorTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v220_submit_response_must_support_requestor
      title 'All must support elements for Profile PAS Requestor Organization are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Requestor Organization Profile.
        This test checks all identified instances of the PAS Requestor Organization
        Profile on responses sent to the client to ensure that the following
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
          profile_key: 'requestor',
          user_input_validation: true,
          ig_version: 'v2.2.0',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end
