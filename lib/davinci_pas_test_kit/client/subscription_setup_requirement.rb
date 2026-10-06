module DaVinciPASTestKit
  # Shared guard for client tests that need the client's Subscription Setup to have completed
  # before they can proceed - either because they need the created Subscription itself (e.g. to
  # generate a notification against it) or just need to know one exists before continuing with
  # the pended scenario.
  module SubscriptionSetupRequirement
    # Skips the test unless a successful (201) Subscription-create request was made during this
    # session, returning that request so a caller that also needs the Subscription itself doesn't
    # have to look it up again.
    # @return [Inferno::Entities::Request] the successful Subscription-create request.
    def require_successful_subscription_create_request
      subscription_request = load_tagged_requests(SUBSCRIPTION_CREATE_TAG).find { |req| req.status == 201 }
      skip_if subscription_request.blank?,
              %(
                This test cannot proceed because no Subscription exists to receive notifications
                for pended claims. Run the _Subscription Setup_ tests to provide a Subscription
                for use in delivering notifications before re-running the pended scenario tests.
              )
      subscription_request
    end
  end
end
