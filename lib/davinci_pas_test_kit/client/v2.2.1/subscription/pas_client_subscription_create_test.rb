require_relative '../../abstract_subscription_create_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubscriptionCreateTest < AbstractSubscriptionCreateTest
      include URLs

      id :pas_client_v221_subscription_create_test
    end
  end
end
