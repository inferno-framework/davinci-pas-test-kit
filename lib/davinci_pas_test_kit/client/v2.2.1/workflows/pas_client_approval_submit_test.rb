require_relative '../../abstract_approval_submit_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientApprovalSubmitTest < AbstractApprovalSubmitTest
      include URLs

      id :pas_client_v221_approval_submit_test
    end
  end
end
