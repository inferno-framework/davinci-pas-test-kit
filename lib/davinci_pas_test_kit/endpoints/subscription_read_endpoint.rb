require_relative '../tags'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class SubscriptionReadEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils

    def test_run_identifier
      request.headers['authorization']&.delete_prefix('Bearer ')
    end

    def make_response
      response.format = :json
      subscription_id = request.params[:id]

      subscription = find_subscription(test_run.test_session_id)

      if subscription.present? && subscription.id == subscription_id
        status_code = determine_subscription_status_code(subscription_id)
        response.body = subscription.source_hash.merge('status' => status_code).to_json
      else
        response.status = 404
        response.body = operation_outcome('error', 'not-found',
                                          "No subscription exists with ID #{subscription_id}").to_json
      end
    end

    def tags
      [SUBSCRIPTION_READ_TAG]
    end
  end
end
