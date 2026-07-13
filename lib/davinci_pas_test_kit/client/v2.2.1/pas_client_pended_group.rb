require_relative 'workflows/pas_client_pended_submit_test'
require_relative 'workflows/pas_client_response_attest'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative '../../pas_notification_conformance_test'
require_relative '../user_input_response'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientPendedGroup < Inferno::TestGroup
      include UserInputResponse

      id :pas_client_v221_pended_group
      title 'Pended Workflow'
      description %(
        During these tests, the client will initiate a prior authorization
        request and show it can respond appropriately to a 'pended' decision, including
        waiting for a full-resource notification that contains the final decision.
        In v2.2.1, the notification includes all details so no follow-up `$inquire`
        request is needed.
      )
      run_as_group

      input :pended_json_response, optional: true

      input_order :pended_json_response,
                  :client_id,
                  :session_url_path

      group do
        title 'Interaction'
        description %(
          All interactions for the pended prior authorization request workflow
          between Inferno and the client under test will be performed during this test
          including
          - A `$submit` request from the client to Inferno where Inferno returns a pended response.
          - A full-resource notification that the prior authorization decision has been finalized
            from Inferno to the client under test.
        )

        test from: :pas_client_v221_pended_submit_test
      end

      group do
        title '$submit Conformance and Handling'

        test from: :pas_client_v221_request_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v221_response_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v221_response_attest,
             title: 'PAS client displays the request as "pended"',
             description: %(
              This test provides the tester an opportunity to observe their client following
              the receipt of the pended response and attest that users are able to determine
              that the response has been pended and a decision will be forthcoming.
             ),
             config: { options: {
               workflow_tag: PENDED_WORKFLOW_TAG,
               attest_message: "I attest that following the receipt of the 'pended' response to the submitted " \
                               'claim, the client system indicates to users that a final decision on request ' \
                               'has not yet been made.'
             } }
      end

      group do
        title 'Notification Conformance and Handling'

        test from: :subscriptions_r4_client_notification_input_verification,
             title: 'Inferno\'s event notification Bundle is conformant',
             description: %(
               This test checks that the notification Bundle sent to the client, which will be either
               the tester-provided notification Bundle in the **Claim updated notification JSON** input
               or mocked by Inferno based on details in the Subscription and submitted Claim, is conformant
               to Subscription Backport IG requirements.
             ),
             simulation_verification: true,
             config: {
               inputs: {
                 notification_bundle: { optional: true } # doesn't use the input (bug in Subscriptions)
               }
             }
        test from: :subscriptions_r4_client_notification_input_payload_verification,
             title: 'Inferno\'s event notification Bundle matches the Subscription',
             description: %(
               This test checks that the notification Bundle sent to the client, which will be either
               the tester-provided notification Bundle in the **Claim updated notification JSON** input
               or mocked by Inferno based on details in the Subscription and submitted Claim, matches the details
               requested in the Subscription provided during the **2.1** "PAS Subscription Setup" tests.
             ),
             simulation_verification: true,
             config: {
               inputs: {
                 notification_bundle: { optional: true } # doesn't use the input (bug in Subscriptions)
               }
             }
        test from: :pas_notification_pas_conformance_test,
             title: 'Inferno\'s notification conforms to PAS-specific requirements',
             simulation_verification: true
        test from: :subscriptions_r4_client_event_notification_verification,
             title: 'PAS client accepts the "claim updated" event notification',
             description: %(
               This test checks that the client responds appropriately to the event notification request.
             ) do
               verifies_requirements(*SubscriptionsTestKit::SubscriptionsR5BackportR4Client::EventNotificationVerificationTest.verifies_requirements,
                                     'hl7.fhir.us.davinci-pas_2.2.1@spec-8')
             end
        test from: :pas_client_v221_response_attest,
             title: 'PAS client displays the final decision as "approved"',
             description: %(
              This test provides the tester an opportunity to observe their client following
              the receipt of the full-resource notification containing the approved final decision
              and attest that users are able to determine that the request has been approved.
             ),
             config: { options: {
               workflow_tag: PENDED_WORKFLOW_TAG,
               attest_message: "I attest that the client system displays the submitted claim as 'approved' based " \
                               'on the full-resource notification, meaning that the user can proceed with ' \
                               'ordering or providing the requested service.'
             } }
      end
    end
  end
end
