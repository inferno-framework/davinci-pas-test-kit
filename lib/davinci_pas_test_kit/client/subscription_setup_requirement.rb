module DaVinciPASTestKit
  # Shared guard for client tests that need the client's Subscription Setup to have completed
  # before they can proceed - either because they need the created Subscription itself (e.g. to
  # generate a notification against it, or to update or delete it) or just need to know one exists
  # before continuing with the pended scenario.
  module SubscriptionSetupRequirement
    PENDED_SCENARIO_SKIP_MESSAGE = %(
      This test cannot proceed because no Subscription exists to receive notifications
      for pended claims. Run the _Subscription Setup_ tests to provide a Subscription
      for use in delivering notifications before re-running the pended scenario tests.
    ).freeze

    PENDED_SCENARIO_MODIFIED_SUBSCRIPTION_SKIP_MESSAGE = %(
      This test cannot proceed because the client submitted update or delete requests for its
      Subscription during the _Subscription Update and Deletion_ tests. Re-run the _Subscription Setup_
      tests to create a new Subscription for use in delivering notifications before re-running the
      pended scenario tests.
    ).freeze

    UPDATE_DELETE_SKIP_MESSAGE = %(
      This test cannot proceed because no Subscription exists to update or delete. Run the
      _Subscription Setup_ tests to create a Subscription before re-running this test.
    ).freeze

    # Skips the test unless a successful (201) Subscription-create request was made during this
    # session, returning that request so a caller that also needs the Subscription itself doesn't
    # have to look it up again.
    # @param skip_message [String] explanation shown when the test is skipped.
    # @return [Inferno::Entities::Request] the successful Subscription-create request.
    def require_successful_subscription_create_request(skip_message: PENDED_SCENARIO_SKIP_MESSAGE)
      subscription_request = load_tagged_requests(SUBSCRIPTION_CREATE_TAG).find { |req| req.status == 201 }
      skip_if subscription_request.blank?, skip_message
      subscription_request
    end

    # Like require_successful_subscription_create_request, but also skips if the client has submitted
    # any update or delete requests for the created Subscription. Notifications are generated from the
    # Subscription as created, so the pended scenario must not run against one the client has since
    # changed or removed.
    # @return [Inferno::Entities::Request] the successful Subscription-create request.
    def require_unmodified_subscription_create_request
      subscription_request = require_successful_subscription_create_request
      # Only update and delete requests are tagged with the Subscription id, which is new for each create
      subscription_id = JSON.parse(subscription_request.response_body)['id']
      skip_if load_tagged_requests(subscription_id).present?, PENDED_SCENARIO_MODIFIED_SUBSCRIPTION_SKIP_MESSAGE
      subscription_request
    end
  end
end
