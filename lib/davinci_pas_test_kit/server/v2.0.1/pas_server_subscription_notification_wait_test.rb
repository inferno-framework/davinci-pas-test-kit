require_relative '../abstract_pas_subscription_notification_wait_test'
require_relative 'urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASSubscriptionNotificationWaitTest < AbstractPASSubscriptionNotificationWaitTest
      include ServerURLs

      id :pas_server_v201_subscription_notification_wait
    end
  end
end
