require_relative '../../abstract_submit_gather_must_support_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubmitGatherMustSupportTest < AbstractSubmitGatherMustSupportTest
      include URLs

      id :pas_client_v201_submit_gather_must_support
    end
  end
end
