require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitRequestServiceRequestMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Service Request are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Service Request Profile.
        This test checks all identified instances of the PAS Service Request
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * ServiceRequest.code
        * ServiceRequest.extension:coverage
        * ServiceRequest.extension:serviceCodeEnd
        * ServiceRequest.occurrence[x]
        * ServiceRequest.quantity[x]
        * ServiceRequest.subject
      )

      id :pas_server_submit_request_v201_service_request_must_support_test

      config(
        options: {
          resource_type: 'ServiceRequest',
          profile_key: 'service_request',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
