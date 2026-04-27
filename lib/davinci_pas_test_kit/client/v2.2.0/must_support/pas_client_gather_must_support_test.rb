require_relative '../../abstract_gather_must_support_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientGatherMustSupportTest < AbstractGatherMustSupportTest
      include URLs

      id :pas_client_v220_gather_must_support
    end
  end
end
