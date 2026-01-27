require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientInquireRequestCoverageMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Coverage are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Coverage Profile.
        This test checks all identified instances of the PAS Coverage
        Profile on requests sent by the client to ensure that the following
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

      id :pas_client_inquire_request_v201_coverage_must_support_test

      config(
        options: {
          resource_type: 'Coverage',
          profile_key: 'coverage',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
