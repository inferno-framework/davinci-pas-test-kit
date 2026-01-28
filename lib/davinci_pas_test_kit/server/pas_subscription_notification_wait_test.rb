require_relative '../cross_suite/urls'

module DaVinciPASTestKit
  class PASSubscriptionNotificationWaitTest < Inferno::Test
    include URLs
    id :pas_subscription_notification_wait
    title 'Server notifies the client that the pended claim was updated.'
    description %(
        This test validates that the server can notify the client that a final
        decision has been made about a pended claim so that the client can query
        for the details. This test depends on a successful subscription creation in
        Test Group **1 Subscription Setup**.
      )

    input :access_token,
          title: 'Notification Access Token',
          description: %(
              An access token that the server under test will send to Inferno on notifications
              so that the request gets associated with this test session. The token must be
              provided as a `Bearer` token in the `Authorization` header of HTTP requests
              sent to Inferno.
            )

    run do
      wait(
        identifier: "notification #{access_token}",
        message: %(
            Inferno has received a 'Pended' claim response indicating that a final decision has not yet been made on the
            prior authorization request.

            Inferno will now wait for a notification at its rest-hook endpoint before making an $inquire request.
            Inferno will automatically resume when a notification is received.

            _If the server is unable to send a notification or if Inferno has not automatically resumed after the server
            attempted to send a notification, you may
            **[click here](#{resume_skip_url}?token=notification+#{access_token})** to skip this test._
          )
      )
    end
  end
end
