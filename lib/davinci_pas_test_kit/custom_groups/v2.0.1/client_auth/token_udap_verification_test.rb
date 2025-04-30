require 'udap_security_test_kit'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientTokenUDAPVerification < UDAPSecurityTestKit::UDAPClientTokenRequestClientCredentialsVerification
      id :pas_client_v201_token_udap_verification

      def client_suite_id
        DaVinciPASTestKit::DaVinciPASV201::ClientSuite.id
      end
    end
  end
end
