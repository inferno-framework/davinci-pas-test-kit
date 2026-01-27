require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireRequestPasInquiryRequestBundleMustSupportTest < DaVinciPASTestKit::MustSupportTest

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
        * Bundle.identifier
        * Bundle.timestamp
      )

      id :pas_server_inquire_request_v201_pas_inquiry_request_bundle_must_support_test

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_inquiry_request_bundle',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
