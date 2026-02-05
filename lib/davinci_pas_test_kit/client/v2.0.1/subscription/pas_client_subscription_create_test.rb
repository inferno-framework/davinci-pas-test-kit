require_relative '../../abstract_subscription_create_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubscriptionCreateTest < AbstractSubscriptionCreateTest
      include URLs

      id :pas_client_v201_subscription_create_test

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@137', 'hl7.fhir.us.davinci-pas_2.0.1@140',
                            'hl7.fhir.us.davinci-pas_2.0.1@142'
    end
  end
end
