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
      This test cannot proceed because the PAS client submitted update or delete requests for its
      Subscription during the _Subscription Update and Deletion_ tests. Re-run the _Subscription Setup_
      tests to create a new Subscription for use in delivering notifications before re-running the
      pended scenario tests.
    ).freeze

    UPDATE_DELETE_SKIP_MESSAGE = %(
      This test cannot proceed because no Subscription exists to update or delete. Run the
      _Subscription Setup_ tests to create a Subscription before re-running this test.
    ).freeze

    # Skips the test unless a successful (201) Subscription-create request was made during this
    # session.
    # @param skip_message [String] explanation shown when the test is skipped.
    # @return [Hash] the created Subscription as returned to the client, parsed from the response body.
    def require_created_subscription(skip_message: PENDED_SCENARIO_SKIP_MESSAGE)
      subscription_request = load_tagged_requests(SUBSCRIPTION_CREATE_TAG).find { |req| req.status == 201 }
      skip_if subscription_request.blank?, skip_message
      JSON.parse(subscription_request.response_body)
    end

    # Like require_created_subscription, but also skips if the client has successfully updated or
    # deleted the created Subscription. Notifications are generated from the Subscription as created,
    # so the pended scenario must not run against one the client has since changed or removed.
    # Rejected update and delete requests leave the Subscription unchanged and so are ignored.
    # @return [Hash] the created Subscription as returned to the client, parsed from the response body.
    def require_unmodified_subscription
      subscription = require_created_subscription
      # Only update and delete requests are tagged with the Subscription id, which is new for each create
      skip_if load_tagged_requests(subscription['id']).any? { |req| subscription_change_succeeded?(req) },
              PENDED_SCENARIO_MODIFIED_SUBSCRIPTION_SKIP_MESSAGE
      subscription
    end

    private

    # Successful updates respond with 200 and successful deletes with a 2xx status
    def subscription_change_succeeded?(request)
      if request.tags.include?(SUBSCRIPTION_DELETE_TAG)
        request.status.between?(200, 299)
      else
        request.status == 200
      end
    end
  end
end
