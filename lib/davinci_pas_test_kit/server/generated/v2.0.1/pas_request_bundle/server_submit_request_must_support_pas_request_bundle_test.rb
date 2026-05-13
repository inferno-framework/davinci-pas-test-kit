require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitRequestMustSupportPasRequestBundleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v201_submit_request_must_support_pas_request_bundle
      title 'All must support elements for Profile PAS Request Bundle are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Request Bundle Profile.
        This test checks all identified instances of the PAS Request Bundle
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:Claim
        * Bundle.identifier
        * Bundle.timestamp
      )

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_request_bundle',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
