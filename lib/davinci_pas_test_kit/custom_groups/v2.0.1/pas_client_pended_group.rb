require_relative 'client_tests/pas_client_pended_submit_test'
require_relative 'client_tests/pas_client_pended_submit_response_attest'
require_relative 'client_tests/pas_client_pended_inquire_test'
require_relative 'client_tests/pas_client_pended_inquire_response_attest'
require_relative '../../custom_groups/v2.0.1/client_tests/pas_client_pended_pas_response_bundle_validation_test'
require_relative '../../custom_groups/v2.0.1/client_tests/pas_client_pas_request_bundle_validation_test'
require_relative '../../custom_groups/v2.0.1/client_tests/pas_client_pended_pas_inquiry_request_bundle_validation_test'
require_relative '../../user_input_response'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedGroup < Inferno::TestGroup
      include UserInputResponse
      id :pas_client_v201_pended_group
      title 'Demonstrate Pended Workflow'
      description %(
        Demonstrate the ability of the client to initiate a prior authorization
        request and respond appropriately to a 'pended' decision, including
        waiting for a notification that an update has been made
        and making an inquiry request to retrieve the final result.
      )
      run_as_group

      input :notification_bundle,
            title: 'Claim Updated Notification Bundle',
            type: 'textarea',
            description: %(
              The event notification bundle that Inferno will send to the client under test to indicate
              that the pended claim has been updated.
            )
      input :pended_json_response,
            title: 'Claim pended response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              The response provided will be validated against the PAS Response Bundle profile.
            )

      group do
        title 'Perform the pended workflow'
        description %(
          All interactions for the pended prior authorization request workflow
          between Inferno and the client under test will be performed during this test
          including
          - $submit request from the client to Inferno where Inferno returns a pended response.
          - Notification that the prior authorization decision has been finalized from Inferno
            to the client under test.
          - $inquire request from the client to Inferno where Inferno returns an approved response.
        )

        test from: :pas_client_v201_pended_submit_test
      end

      group do
        title 'Verify $submit interaction'

        test from: :pas_client_v201_pas_request_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v201_pended_pas_response_bundle_validation_test
        test from: :pas_client_v201_pended_submit_response_attest
      end

      group do
        title 'Verify notification interaction'

        test from: :subscriptions_r4_client_notification_input_verification,
             title: '[USER INPUT VERIFICATION] Tester-provided event notification Bundle is conformant',
             description: %(
               The '**Claim Updated Notification Bundle**' input contains a conformant notification.
             )
        test from: :subscriptions_r4_client_notification_input_payload_verification,
             title: '[USER INPUT VERIFICATION] Tester-provided event notification Bundle matches the Subscription',
             description: %(
               The '**Claim Updated Notification Bundle**' input contains a notification bundle with a content
               level that matches what was requested in the Subscription sent during the _PAS Subscription Setup_
               group.
             )
        # test for PAS-specific requirements? Current decision: no, there isn't anything hard in the spec
        # and testers have to demonstrate and attest that their systems work, which will require some
        # correspondence.
        test from: :subscriptions_r4_client_event_notification_verification,
             title: 'Client accepts the "claim updated" event notification',
             description: %(
               The client responds appropriately to the event notification request.
             )
      end

      group do
        title 'Verify $inquire interaction'

        test from: :pas_client_v201_pended_pas_inquiry_request_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }

        test from: :pas_client_v201_pended_inquire_response_attest
      end
    end
  end
end
