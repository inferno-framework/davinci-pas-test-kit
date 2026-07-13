require_relative '../../abstract_gather_must_support_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientGatherMustSupportTest < AbstractGatherMustSupportTest
      include URLs

      id :pas_client_v221_gather_must_support
    end
  end
end
