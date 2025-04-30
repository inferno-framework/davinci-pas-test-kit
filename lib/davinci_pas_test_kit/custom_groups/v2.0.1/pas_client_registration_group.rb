require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../../client_suite'
require_relative 'client_options'
require_relative 'client_registration/configuration_display_smart_test'
require_relative 'client_registration/configuration_display_udap_test'
require_relative 'client_registration/configuration_display_other_test'
require_relative 'client_registration/other_auth_attest_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientRegistrationGroup < Inferno::TestGroup
      id :pas_client_v201_registration
      title 'Client Registration'
      description %(
        Register the client under test with Inferno's simulated PAS Server,
        including configuration of the system under test to hit the correct endpoints and
        enable authentication and authorization of PAS requests.

        If this set of tests is not run before the other tests, Inferno will default to use
        the **Dedicated Endpoints** approach using the session identifier to create the custom
        endpoints.

        When running these tests there are 4 options for authentication:
        1. **UDAP B2B client credentials flow**: the system under test will dynamically register
           with Inferno and request access tokens used to access FHIR endpoints
           as per the UDAP specification.
        2. **SMART Backend Services**: the system under test will manually register
           with Inferno and request access token used to access FHIR endpoints
           as per the SMART Backend Services specification.
        3. **Both UDAP and SMART**: the system under test will register as both a SMART
           and a UDAP client, using the same client id for both. If this path is chosen
           both authentication approaches will need to be demonstrated during the
           subsequent tests.
        4. **Dedicated Endpoints**: Inferno will create a dedicated set of FHIR endpoints for this session
           so that the system under test does not need to get access tokens or provide
           them during these tests. Since PAS requires authentication of client systems,
           testers will be asked to attest that their system supports another form of
           authentication, such as mutual authentication TLS.
      )
      run_as_group

      # smart registration tests
      test from: :smart_client_registration_bsca_verification,
           required_suite_options: {
             client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
           }
      test from: :pas_client_v201_reg_config_smart_display,
           required_suite_options: {
             client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
           }

      # udap registration tests
      test from: :udap_client_registration_interaction,
           required_suite_options: {
             client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
           },
           config: {
             options: { endpoint_suite_id: :davinci_pas_client_suite_v201 }
           }
      test from: :udap_client_registration_cc_verification,
           required_suite_options: {
             client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
           },
           config: {
             options: { endpoint_suite_id: :davinci_pas_client_suite_v201 }
           }
      test from: :pas_client_v201_reg_config_udap_display,
           required_suite_options: {
             client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
           }

      # other registration tests
      test from: :pas_client_v201_reg_other_auth_attest,
           required_suite_options: {
             client_type: PASClientOptions::DEDICATED_ENDPOINTS
           }
      test from: :pas_client_v201_reg_config_other_display,
           required_suite_options: {
             client_type: PASClientOptions::DEDICATED_ENDPOINTS
           }
    end
  end
end
