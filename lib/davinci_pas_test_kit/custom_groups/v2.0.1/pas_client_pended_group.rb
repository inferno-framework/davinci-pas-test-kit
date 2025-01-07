require_relative 'client_tests/pas_client_pended_submit_test'
require_relative 'client_tests/pas_client_pended_submit_response_attest'
require_relative 'client_tests/pas_client_pended_inquire_test'
require_relative 'client_tests/pas_client_pended_inquire_response_attest'
require_relative 'client_tests/pas_client_pended_pas_response_bundle_validation_test'
require_relative 'client_tests/pas_client_pended_inquire_response_bundle_validation_test'
require_relative 'client_tests/pas_client_pas_request_bundle_validation_test'
require_relative 'client_tests/pas_client_pended_pas_inquiry_request_bundle_validation_test'
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
            optional: true,
            description: %(
              If provided, this JSON will be sent as the notification for the
              PAS Subscription to tell the client that a decision has been made on the pended claim.
              It will be updated to make creation timestamps current refer to the correct
              ClaimResponse id if it was mocked by Inferno.
              If not provided, a notification will be generated from the returned ClaimResponse.
              In either case the response will be validated to ensure that the notification
              is conformant.
            )
      input :pended_json_response,
            title: 'Claim pended response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $submit requests during this test
              to indicate that the request has been pended awaaiting a final decision.
              It will be updated to make creation timestamps current.
              If not provided, a pended response will be generated from the submitted Claim.
              In either case the response will be validated against the PAS Response Bundle profile.
            )
      input :inquire_json_response,
            title: 'Inquire response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $inquire requests during this test
              to indicate that the request has been approved.
              It will be updated to make creation timestamps current.
              If not provided, an approval response will be generated from the submitted Claim.
              In either case, the response will be validated against the PAS Response Bundle profile.
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
        test from: :pas_client_v201_pended_inquire_response_bundle_validation_test
        test from: :pas_client_v201_pended_inquire_response_attest
      end
    end
  end
end
