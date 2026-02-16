require_relative 'cross_suite/pas_notification_verification'
require_relative 'cross_suite/tags'

module DaVinciPASTestKit
  class NotificationPASConformanceTest < Inferno::Test
    include PASNotificationVerification

    id :pas_notification_pas_conformance_test
    title 'Notification conforms to PAS-specific requirements'
    description %(
      This test verifies that the notification sent to the client under test
      for a pended claim update (or sent by the server under test) conforms
      to PAS-specific requirements beyond the base Subscription Backport IG
      notification requirements. In particular, the focus resource in the
      notification should be the updated ClaimResponse conformant to the
      PAS Response Bundle profile.
    )

    run do
      load_tagged_requests(REST_HOOK_EVENT_NOTIFICATION_TAG)
      skip_if(requests.none?, 'Inferno did not send or receive an event notification')

      notification_body = request.request_body
      verify_pas_notification(notification_body)
    end
  end
end
