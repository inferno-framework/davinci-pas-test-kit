require_relative '../../abstract_subscription_create_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientSubscriptionCreateTest < AbstractSubscriptionCreateTest
      include URLs

      id :pas_client_v220_subscription_create_test
    end
  end
end
