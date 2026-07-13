require_relative '../../abstract_response_attest'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientResponseAttest < AbstractResponseAttest
      include URLs

      id :pas_client_v221_response_attest
    end
  end
end
