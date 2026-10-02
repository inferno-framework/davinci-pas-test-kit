require_relative 'workflows/pas_client_pended_submit_test'
require_relative 'workflows/pas_client_response_attest'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_response_bundle_validation_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_request_bundle_validation_test'
require_relative '../user_input_response'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedGroup < Inferno::TestGroup
      include UserInputResponse

      id :pas_client_v201_pended_group
      title 'Pended Response'
      description %(
        During these tests, the client system will initiate a prior authorization
        request and show it can react appropriately to a 'pended' decision, including
        waiting for a notification that an update has been made
        and making an inquiry request to retrieve the final result.
      )
      run_as_group

      input :pended_json_response, optional: true
      input :inquire_json_response, optional: true

      input_order :pended_json_response,
                  :inquire_json_response,
                  :client_id,
                  :session_url_path

      group do
        title 'Perform the pended scenario'
        description %(
          All interactions for the pended prior authorization request scenario
          between Inferno and the client system will be performed during this group
          including
          - A `$submit` request from the client to Inferno where Inferno returns a pended response.
          - A notification that the prior authorization decision has been finalized from Inferno
            to the client system.
          - An `$inquire` request from the client to Inferno where Inferno returns an approved response.
        )

        test from: :pas_client_v201_pended_submit_test
      end

      group do
        title 'Verify $submit interaction'

        test from: :pas_client_v201_request_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v201_response_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v201_response_attest,
             title: 'Check that the client registers the request as pended',
             description: %(
              During this test, the tester will observe the client system following
              the receipt of the pended response and attest that users are able to determine
              that the response has been pended and a decision will be forthcoming.
             ),
             config: { options: {
               workflow_tag: PENDED_WORKFLOW_TAG,
               operation_tag: SUBMIT_TAG,
               multiple_requests_ok: true,
               attest_message: "I attest that following the receipt of the 'pended' response to the submitted " \
                               'claim, the client system indicates to users that a final decision on request ' \
                               'has not yet been made.'
             } }
      end

      group do
        title 'Verify notification interaction'

        test from: :subscriptions_r4_client_notification_input_verification,
             title: 'Tester-provided event notification Bundle is conformant',
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
             title: 'Tester-provided event notification Bundle matches the Subscription',
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
        # test for PAS-specific requirements? Current decision: no, there isn't anything hard in the spec
        # and testers have to demonstrate and attest that their systems work, which will require some
        # correspondence.
        test from: :subscriptions_r4_client_event_notification_verification,
             title: 'Client accepts the "claim updated" event notification',
             description: %(
               This test checks that the client responds appropriately to the event notification request.
             )
      end

      group do
        title 'Verify $inquire interaction'

        test from: :pas_client_v201_inquire_request_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v201_inquire_response_bundle_validation_test,
             config: { options: { workflow_tag: PENDED_WORKFLOW_TAG } }
        test from: :pas_client_v201_response_attest,
             title: 'Check that the client registers the request as approved',
             description: %(
              During this test, the tester will observe the client system following
              the receipt of the inquiry response with a final decision and attest that users
              are able to determine that the response has been approved in full.
             ),
             config: { options: {
               workflow_tag: PENDED_WORKFLOW_TAG,
               operation_tag: INQUIRE_TAG,
               multiple_requests_ok: true,
               attest_message: 'I attest that the client system did not error when handling the `$inquire` ' \
                               "response and displays the submitted claim as 'approved' meaning that the " \
                               'user can proceed with ordering or providing the requested service.'
             } }
      end
    end
  end
end
