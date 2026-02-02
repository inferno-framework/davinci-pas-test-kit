require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../pas_client_options'
require_relative '../registration/configuration_smart_display_test'
require_relative '../registration/configuration_udap_display_test'
require_relative '../registration/configuration_other_display_test'
require_relative '../registration/other_auth_attest_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientRegistrationGroup < Inferno::TestGroup
      id :pas_client_v220_registration
      title 'Client Registration'
      description %(
        Register the client under test with Inferno's simulated PAS Server,
        including configuration of the system under test to make requests against
        Inferno's simulated PAS endpoints and enable authentication and authorization of PAS requests.
      )
      run_as_group

      # smart registration tests
      test from: :smart_client_registration_bsca_verification,
           required_suite_options: {
             client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
           }
      test from: :pas_client_reg_config_smart_display,
           id: :pas_client_v220_reg_config_smart_display,
           required_suite_options: {
             client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
           }

      # udap registration tests
      test from: :udap_client_registration_interaction,
           required_suite_options: {
             client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
           },
           config: {
             options: { endpoint_suite_id: :davinci_pas_client_suite_v220 }
           }
      test from: :udap_client_registration_cc_verification,
           required_suite_options: {
             client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
           },
           config: {
             options: { endpoint_suite_id: :davinci_pas_client_suite_v220 }
           }
      test from: :pas_client_reg_config_udap_display,
           id: :pas_client_v220_reg_config_udap_display,
           required_suite_options: {
             client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
           }

      # other registration tests
      test from: :pas_client_reg_other_auth_attest,
           id: :pas_client_v220_reg_other_auth_attest,
           required_suite_options: {
             client_type: PASClientOptions::OTHER_AUTH
           }
      test from: :pas_client_reg_config_other_display,
           id: :pas_client_v220_reg_config_other_display,
           required_suite_options: {
             client_type: PASClientOptions::OTHER_AUTH
           }
    end
  end
end
