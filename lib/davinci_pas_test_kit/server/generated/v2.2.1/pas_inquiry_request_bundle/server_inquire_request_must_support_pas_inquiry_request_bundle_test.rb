require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ServerInquireRequestMustSupportPasInquiryRequestBundleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v221_inquire_request_must_support_pas_inquiry_request_bundle
      title 'All must support elements for Profile PAS Inquiry Request Bundle are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Inquiry Request Bundle Profile.
        This test checks all identified instances of the PAS Inquiry Request Bundle
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:Claim
        * Bundle.entry:Claim.fullUrl
        * Bundle.entry:Claim.resource
        * Bundle.identifier
        * Bundle.timestamp
      )

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_inquiry_request_bundle',
          user_input_validation: true,
          ig_version: 'v2.2.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
