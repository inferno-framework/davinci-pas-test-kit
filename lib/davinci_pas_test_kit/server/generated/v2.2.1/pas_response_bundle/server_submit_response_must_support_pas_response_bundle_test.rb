require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ServerSubmitResponseMustSupportPasResponseBundleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v221_submit_response_must_support_pas_response_bundle
      title 'All must support elements for Profile PAS Response Bundle are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Response Bundle Profile.
        This test checks all identified instances of the PAS Response Bundle
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:ClaimResponse
        * Bundle.entry:ClaimResponse.fullUrl
        * Bundle.entry:ClaimResponse.resource
        * Bundle.identifier
        * Bundle.timestamp
      )

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_response_bundle',
          user_input_validation: false,
          ig_version: 'v2.2.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end
