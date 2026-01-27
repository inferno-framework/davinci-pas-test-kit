require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitResponseTaskMustSupportTest < DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Task are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Task Profile.
        This test checks all identified instances of the PAS Task
        Profile on responses returned by the server to ensure that the following
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

      id :pas_server_submit_response_v201_task_must_support_test

      config(
        options: {
          resource_type: 'Task',
          profile_key: 'task',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end
