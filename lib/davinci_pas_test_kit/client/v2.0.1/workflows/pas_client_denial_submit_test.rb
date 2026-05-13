require_relative '../../abstract_denial_submit_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientDenialSubmitTest < AbstractDenialSubmitTest
      include URLs

      id :pas_client_v201_denial_submit_test

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@58', 'hl7.fhir.us.davinci-pas_2.0.1@62',
                            'hl7.fhir.us.davinci-pas_2.0.1@70', 'hl7.fhir.us.davinci-pas_2.0.1@202'
    end
  end
end
