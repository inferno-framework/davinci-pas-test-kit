require_relative '../../abstract_response_attest'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientResponseAttest < AbstractResponseAttest
      include URLs

      id :pas_client_v201_response_attest
    end
  end
end
