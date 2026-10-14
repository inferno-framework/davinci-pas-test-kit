require_relative '../../cross_suite/tags'
require_relative 'session_identification'
require_relative 'expired_token'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class SubscriptionDeleteEndpoint < SubscriptionsTestKit::SubscriptionDeleteEndpoint
    include SessionIdentification
    prepend ExpiredTokenRejection

    error_response_format :operation_outcome
  end
end
