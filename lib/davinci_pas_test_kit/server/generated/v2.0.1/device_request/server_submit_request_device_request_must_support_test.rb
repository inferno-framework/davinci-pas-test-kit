require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitRequestDeviceRequestMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Device Request are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Device Request Profile.
        This test checks all identified instances of the PAS Device Request
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * DeviceRequest.code[x]
        * DeviceRequest.extension:coverage
        * DeviceRequest.occurrence[x]
        * DeviceRequest.subject
      )

      id :pas_server_submit_request_v201_device_request_must_support_test

      config(
        options: {
          resource_type: 'DeviceRequest',
          profile_key: 'device_request',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
