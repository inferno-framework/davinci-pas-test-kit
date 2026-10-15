require_relative '../../abstract_subscription_update_delete_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubscriptionUpdateDeleteTest < AbstractSubscriptionUpdateDeleteTest
      include URLs

      id :pas_client_v221_subscription_update_delete_test
    end
  end
end
