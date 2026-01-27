require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientInquireRequestPasInquiryRequestBundleMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Inquiry Request Bundle are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Inquiry Request Bundle Profile.
        This test checks all identified instances of the PAS Inquiry Request Bundle
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:Claim
        * Bundle.identifier
        * Bundle.timestamp
      )

      id :pas_client_inquire_request_v201_pas_inquiry_request_bundle_must_support_test

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_inquiry_request_bundle',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
