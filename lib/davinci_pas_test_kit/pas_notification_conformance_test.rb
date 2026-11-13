require_relative 'cross_suite/pas_bundle_validation'
require_relative 'cross_suite/pas_notification_verification'
require_relative 'cross_suite/tags'

module DaVinciPASTestKit
  # Options:
  # - focus_validator: validator for the focus PAS Response Bundle. When not set, only structure is checked.
  # - echo_source_tags: tags of the $submit request the focus Bundle answers (the latest successful one is used)
  class NotificationPASConformanceTest < Inferno::Test
    include PasBundleValidation
    include PASNotificationVerification

    id :pas_notification_pas_conformance_test
    title 'Notification conforms to PAS-specific requirements'
    description %(
      This test verifies that the notification sent to the client system
      for a pended claim update conforms
      to PAS-specific requirements beyond the base Subscription Backport IG
      notification requirements. In particular, the focus resource in the
      notification should be the updated ClaimResponse conformant to the
      PAS Response Bundle profile.
    )

    run do
      # Client tests tag the outgoing notification with REST_HOOK_EVENT_NOTIFICATION_TAG
      load_tagged_requests(REST_HOOK_EVENT_NOTIFICATION_TAG)

      # Server tests tag incoming notifications with the Subscription ID
      if requests.none?
        subscription_requests = load_tagged_requests('subscription_creation').select { |req| req.status == 201 }
        latest_subscription = subscription_requests.max_by(&:created_at)

        if latest_subscription.present?
          subscription = JSON.parse(latest_subscription.response_body)
          load_tagged_requests(subscription['id'])
        end
      end

      skip_if(requests.none?, 'Inferno did not send or receive an event notification')

      notification_body = request.request_body
      verify_pas_notification(notification_body, focus_validator: config.options[:focus_validator],
                                                 echoed_from: echo_source_request&.request_body)
    end

    def echo_source_request
      tags = config.options[:echo_source_tags]
      return if tags.blank?

      Inferno::Repositories::Requests.new.tagged_requests(test_session_id, tags)
        .select { |req| req.status == 200 }
        .max_by(&:index)
    end
  end
end
