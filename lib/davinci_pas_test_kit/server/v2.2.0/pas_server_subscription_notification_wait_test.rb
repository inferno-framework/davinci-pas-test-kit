require_relative '../abstract_pas_subscription_notification_wait_test'
require_relative 'server_urls'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASSubscriptionNotificationWaitTest < AbstractPASSubscriptionNotificationWaitTest
      include ServerURLs

      id :pas_server_v220_subscription_notification_wait

      receives_request :notification
    end
  end
end
