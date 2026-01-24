require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireResponsePasInquiryResponseBundleMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Inquiry Response Bundle are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Inquiry Response Bundle Profile.
        This test checks all identified instances of the PAS Inquiry Response Bundle
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:ClaimResponse
        * Bundle.timestamp
      )

      id :pas_server_inquire_response_v201_pas_inquiry_response_bundle_must_support_test

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_inquiry_response_bundle',
          user_input_validation: false,
          version: 'v2.0.1',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
