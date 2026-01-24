require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestServiceRequestMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Service Request are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Service Request Profile.
        This test checks all identified instances of the PAS Service Request
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * ServiceRequest.code
        * ServiceRequest.extension:coverage
        * ServiceRequest.extension:serviceCodeEnd
        * ServiceRequest.occurrence[x]
        * ServiceRequest.quantity[x]
        * ServiceRequest.subject
      )

      id :pas_client_submit_request_v201_service_request_must_support_test

      config(
        options: {
          resource_type: 'ServiceRequest',
          profile_key: 'service_request',
          user_input_validation: false,
          version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
