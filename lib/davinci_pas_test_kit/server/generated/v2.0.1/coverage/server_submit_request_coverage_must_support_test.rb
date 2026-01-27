require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitRequestCoverageMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Coverage are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Coverage Profile.
        This test checks all identified instances of the PAS Coverage
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * Coverage.beneficiary
        * Coverage.identifier
        * Coverage.payor
        * Coverage.relationship
        * Coverage.relationship.coding:X12Code
        * Coverage.status
        * Coverage.subscriber
        * Coverage.subscriberId
      )

      id :pas_server_submit_request_v201_coverage_must_support_test

      config(
        options: {
          resource_type: 'Coverage',
          profile_key: 'coverage',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
