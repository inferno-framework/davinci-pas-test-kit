require 'smart_app_launch_test_kit'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientTokenUSMARTVerification <
      SMARTAppLaunch::SMARTClientTokenRequestBackendServicesConfidentialAsymmetricVerification
      id :pas_client_v201_token_smart_verification

      def client_suite_id
        DaVinciPASTestKit::DaVinciPASV201::ClientSuite.id
      end
    end
  end
end
