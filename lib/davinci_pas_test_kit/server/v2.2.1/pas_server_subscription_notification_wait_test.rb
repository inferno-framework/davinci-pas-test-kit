require_relative '../abstract_pas_subscription_notification_wait_test'
require_relative 'server_urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASSubscriptionNotificationWaitTest < AbstractPASSubscriptionNotificationWaitTest
      include ServerURLs

      id :pas_server_v221_subscription_notification_wait
    end
  end
end
