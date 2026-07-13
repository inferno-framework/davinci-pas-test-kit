require_relative '../../abstract_denial_submit_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientDenialSubmitTest < AbstractDenialSubmitTest
      include URLs

      id :pas_client_v221_denial_submit_test
    end
  end
end
