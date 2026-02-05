require_relative '../../abstract_inquire_gather_must_support_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientInquireGatherMustSupportTest < AbstractInquireGatherMustSupportTest
      include URLs

      id :pas_client_v201_inquire_gather_must_support
    end
  end
end
