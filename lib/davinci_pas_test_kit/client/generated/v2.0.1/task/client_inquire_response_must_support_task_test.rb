require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientInquireResponseMustSupportTaskTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v201_inquire_response_must_support_task
      title 'All must support elements for Profile PAS Task are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Task Profile.
        This test checks all identified instances of the PAS Task
        Profile on responses sent to the client to ensure that the following
        must support elements are observed:

        * Task.code
        * Task.for
        * Task.identifier
        * Task.input
        * Task.intent
        * Task.owner
        * Task.owner.identifier
        * Task.reasonCode.coding.code
        * Task.reasonReference
        * Task.requester
        * Task.requester.identifier
        * Task.restriction.period
        * Task.status
        * Task.statusReason
      )

      config(
        options: {
          resource_type: 'Task',
          profile_key: 'task',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
