require_relative '../../registration/abstract_other_auth_attest_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class RegistrationOtherAuthAttest < AbstractRegistrationOtherAuthAttest
      include URLs

      id :pas_client_v221_reg_other_auth_attest
    end
  end
end
