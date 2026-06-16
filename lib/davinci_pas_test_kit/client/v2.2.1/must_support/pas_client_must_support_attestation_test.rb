require_relative '../../../cross_suite/must_support/must_support_attestation_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientMustSupportAttestationTest < DaVinciPASTestKit::MustSupportAttestationTest
      include URLs

      id :pas_client_v221_must_support_attestation
      title 'Observed or attested must support elements'
    end
  end
end
