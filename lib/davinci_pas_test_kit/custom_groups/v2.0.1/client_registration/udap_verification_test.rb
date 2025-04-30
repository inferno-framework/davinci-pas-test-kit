require 'udap_security_test_kit'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientRegistrationUDAPVerification <
        UDAPSecurityTestKit::UDAPClientRegistrationClientCredentialsVerification
      id :pas_client_v201_reg_udap_verification

      def client_suite_id
        DaVinciPASTestKit::DaVinciPASV201::ClientSuite.id
      end
    end
  end
end
