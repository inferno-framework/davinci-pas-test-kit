module DaVinciPASTestKit
  module DaVinciPASV201
    class PasUpdateNotificationTest < Inferno::Test
      id :prior_auth_claim_response_update_notification_validation
      title 'Server notifies the client that the pended claim was updated.'
      description %(
        This test validates that the server can notify the client that a final
        decision has been made about a pended claim so that the client can query
        for the details. Currently, testers attest that the decision on the prior
        authorization request has been finalized so that Inferno can check the rest of
        the pended workflow. In the future, Inferno will validate that the server
        can accept requests for a subscription and send notifications alerting the client
        to the availability of updates to the prior authorization request (see details on this limitation
        [here](https://github.com/inferno-framework/davinci-pas-test-kit/tree/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations)).
      )

      run do
        # rubocop:disable Layout/LineLength
        wait(
          identifier: 'pended',
          message: %(
            Inferno has received a 'Pended' claim response indicating that a final decision
            has not yet been made on the prior authorization request.

            Please
            **[click
            here](#{Inferno::Application['base_url']}/custom/davinci_pas_server_suite_v201/resume_after_notification?use_case=pended)**
            when the status of this claim has been finalized to inform Inferno to resume testing.

            Future versions of this test will validate subscription-based notifications as
            described within the implementation guide (see
            [here](https://github.com/inferno-framework/davinci-pas-test-kit/tree/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations)
            for more details on this current limitation).
          )
        )
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
