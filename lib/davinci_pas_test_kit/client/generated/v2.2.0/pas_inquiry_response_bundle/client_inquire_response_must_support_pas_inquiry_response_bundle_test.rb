require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ClientInquireResponseMustSupportPasInquiryResponseBundleTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v220_inquire_response_must_support_pas_inquiry_response_bundle
      title 'All must support elements for Profile PAS Inquiry Response Bundle are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Inquiry Response Bundle Profile.
        This test checks all identified instances of the PAS Inquiry Response Bundle
        Profile on responses sent to the client to ensure that the following
        must support elements are observed:

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:ClaimResponse
        * Bundle.entry:ClaimResponse.fullUrl
        * Bundle.entry:ClaimResponse.resource
        * Bundle.timestamp
      )

      config(
        options: {
          resource_type: 'Bundle',
          profile_key: 'pas_inquiry_response_bundle',
          user_input_validation: true,
          ig_version: 'v2.2.0',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
