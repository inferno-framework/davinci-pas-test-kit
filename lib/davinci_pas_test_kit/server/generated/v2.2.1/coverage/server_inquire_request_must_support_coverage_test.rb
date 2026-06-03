require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ServerInquireRequestMustSupportCoverageTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v221_inquire_request_must_support_coverage
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
        * Coverage.class
        * Coverage.class:group
        * Coverage.class:group.name
        * Coverage.class:group.value
        * Coverage.class:plan
        * Coverage.class:plan.name
        * Coverage.class:plan.value
        * Coverage.identifier
        * Coverage.identifier:memberid
        * Coverage.identifier:memberid.type
        * Coverage.payor
        * Coverage.period
        * Coverage.relationship
        * Coverage.relationship.coding:X12Code
        * Coverage.status
        * Coverage.subscriber
        * Coverage.subscriberId
        * Coverage.type
      )

      config(
        options: {
          resource_type: 'Coverage',
          profile_key: 'coverage',
          user_input_validation: true,
          ig_version: 'v2.2.1',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
