require 'subscriptions_test_kit'
require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../../cross_suite/validator_suppressions'
require_relative '../../cross_suite/tags'
require_relative '../endpoints/claim_endpoint'
require_relative '../endpoints/token_endpoint'
require_relative '../endpoints/subscription_create_endpoint'
require_relative '../endpoints/subscription_status_endpoint'
require_relative '../metadata/mock_pas_server'
require_relative '../pas_client_options'
require_relative 'pas_client_workflows_group'
require_relative 'pas_client_must_support_group'
require_relative 'pas_client_subscription_setup_group'
require_relative 'pas_client_registration_group'
require_relative 'pas_client_auth_smart_group'
require_relative 'pas_client_auth_udap_group'
require_relative 'pas_client_error_handling_group'
require_relative '../client_input_descriptions'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ClientSuite < Inferno::TestSuite
      id :davinci_pas_client_suite_v221
      title 'Da Vinci PAS Client Suite v2.2.1'
      description <<~DESCRIPTION
        The Da Vinci PAS Client v2.2.1 Test Suite tests the conformance of systems to the
        capabilities of a PAS client as described in [version 2.2.1](https://hl7.org/fhir/us/davinci-pas/2.2.1)
        of the Da Vinci Prior Authorization Support (PAS) Implementation Guide.

        These tests are a **DRAFT** intended to allow PAS implementers to perform
        preliminary checks of their implementations against the PAS IG requirements and
        [provide feedback](https://github.com/inferno-framework/davinci-pas-test-kit/issues) on the tests.
        Future versions of these tests may validate other requirements and may change how these are tested.

        Detailed information about this test suite can be found in the
        [client section](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details) of the
        [PAS Test Kit Wiki](https://github.com/inferno-framework/davinci-pas-test-kit/wiki), including:
        - [What testers need to successfully execute these tests](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Instructions-v2.2.1#pre-execution-setup-and-required-information),
        - [Minimal](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Instructions-v2.2.1#quick-start)
          and [complete](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Instructions-v2.2.1#additional-testing-options)
          instructions for executing against a client system, and
        - How to [interpret test results](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Instructions-v2.2.1#interpreting-results).
      DESCRIPTION

      suite_summary <<~SUMMARY
        The Da Vinci PAS Client v2.2.1 Test Suite tests the conformance of client systems
        to [version 2.2.1 of the Da Vinci Prior Authorization Support (PAS)
        Implementation Guide](https://hl7.org/fhir/us/davinci-pas/2.2.1).
      SUMMARY

      links [
        {
          label: 'Report Issue',
          url: 'https://github.com/inferno-framework/davinci-pas-test-kit/issues/'
        },
        {
          label: 'Open Source',
          url: 'https://github.com/inferno-framework/davinci-pas-test-kit/'
        },
        {
          label: 'Download',
          url: 'https://github.com/inferno-framework/davinci-pas-test-kit/releases'
        },
        {
          label: 'Implementation Guide',
          url: 'https://hl7.org/fhir/us/davinci-pas/2.2.1/'
        }
      ]

      requirement_sets(
        {
          identifier: 'hl7.fhir.us.davinci-pas_2.2.1',
          title: 'Da Vinci Prior Authorization Support (PAS) v2.2.1',
          actor: 'PAS Client'
        },
        {
          identifier: 'hl7.fhir.uv.subscriptions_1.1.0',
          title: 'Subscriptions R5 Backport IG',
          actor: 'Client'
        }
      )

      fhir_resource_validator do
        igs('hl7.fhir.us.davinci-pas#2.2.1', 'hl7.fhir.us.core#6.1.0')

        exclude_message do |message|
          # Messages expected of the form `<ResourceType>: <FHIRPath>: <message>`
          # We strip `<ResourceType>: <FHIRPath>: ` for the sake of matching
          SUPPRESSED_MESSAGES.match?(message.message.sub(/\A\S+: \S+: /, ''))
        end
      end

      suite_option :client_type,
                   title: 'Client Security Type',
                   list_options: [
                     {
                       label: 'SMART Backend Services',
                       value: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
                     },
                     {
                       label: 'UDAP B2B Client Credentials',
                       value: PASClientOptions::UDAP_CLIENT_CREDENTIALS
                     },
                     {
                       label: 'Other Authentication',
                       value: PASClientOptions::OTHER_AUTH
                     }
                   ]

      route(:get, UDAPSecurityTestKit::UDAP_DISCOVERY_PATH, lambda { |_env|
        UDAPSecurityTestKit::MockUDAPServer.udap_server_metadata(id)
      })
      route(:get, SMARTAppLaunch::SMART_DISCOVERY_PATH, lambda { |_env|
        SMARTAppLaunch::MockSMARTServer.smart_server_metadata(id)
      })

      # FHIR capability statement for the simulated PAS payer server, declaring
      # subscription support as required by the PAS IG.
      route(:get, FHIR_METADATA_PATH, lambda { |env|
        MockPASServer.capability_statement_response(env)
      })
      route(:get, SESSION_FHIR_METADATA_PATH, lambda { |env|
        MockPASServer.capability_statement_response(env)
      })

      suite_endpoint :post, UDAPSecurityTestKit::REGISTRATION_PATH,
                     UDAPSecurityTestKit::MockUDAPServer::RegistrationEndpoint
      suite_endpoint :post, UDAPSecurityTestKit::TOKEN_PATH, MockUdapSmartServer::TokenEndpoint

      suite_endpoint :post, SUBMIT_PATH, ClaimEndpoint
      suite_endpoint :post, SESSION_SUBMIT_PATH, ClaimEndpoint
      suite_endpoint :post, INQUIRE_PATH, ClaimEndpoint
      suite_endpoint :post, SESSION_INQUIRE_PATH, ClaimEndpoint
      suite_endpoint :post, FHIR_SUBSCRIPTION_PATH, SubscriptionCreateEndpoint
      suite_endpoint :post, SESSION_FHIR_SUBSCRIPTION_PATH, SubscriptionCreateEndpoint
      suite_endpoint :get, FHIR_SUBSCRIPTION_INSTANCE_PATH, SubscriptionsTestKit::SubscriptionReadEndpoint
      suite_endpoint :get, SESSION_FHIR_SUBSCRIPTION_INSTANCE_PATH, SubscriptionsTestKit::SubscriptionReadEndpoint
      suite_endpoint :post, FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SubscriptionStatusEndpoint
      suite_endpoint :post, SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SubscriptionStatusEndpoint
      suite_endpoint :get, FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SubscriptionStatusEndpoint
      suite_endpoint :get, SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SubscriptionStatusEndpoint
      suite_endpoint :post, FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH, SubscriptionStatusEndpoint
      suite_endpoint :post, SESSION_FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH, SubscriptionStatusEndpoint
      allow_cors UDAPSecurityTestKit::UDAP_DISCOVERY_PATH, SMARTAppLaunch::SMART_DISCOVERY_PATH,
                 FHIR_METADATA_PATH, SESSION_FHIR_METADATA_PATH,
                 UDAPSecurityTestKit::REGISTRATION_PATH, UDAPSecurityTestKit::TOKEN_PATH,
                 SUBMIT_PATH, SESSION_SUBMIT_PATH, INQUIRE_PATH, SESSION_INQUIRE_PATH,
                 FHIR_SUBSCRIPTION_PATH, SESSION_FHIR_SUBSCRIPTION_PATH,
                 FHIR_SUBSCRIPTION_INSTANCE_PATH, SESSION_FHIR_SUBSCRIPTION_INSTANCE_PATH,
                 FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH,
                 FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH, SESSION_FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH

      resume_test_route :get, RESUME_PASS_PATH do |request|
        request.query_parameters['token']
      end

      resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
        request.query_parameters['token']
      end

      group from: :pas_client_v221_registration

      # SMART test groups (with :session_url_path input removed)
      group from: :pas_client_v221_subscription_setup, id: :pas_client_v221_subscription_setup_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v221_workflows, id: :pas_client_v221_workflows_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v221_must_support, id: :pas_client_v221_must_support_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v221_error_handling_group, id: :pas_client_v221_error_handling_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end

      # UDAP test groups (with :session_url_path input removed)
      group from: :pas_client_v221_subscription_setup, id: :pas_client_v221_subscription_setup_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v221_workflows, id: :pas_client_v221_workflows_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v221_must_support, id: :pas_client_v221_must_support_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v221_error_handling_group, id: :pas_client_v221_error_handling_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end

      # Dedicated Endpoints test groups (with :client_id input removed)
      group from: :pas_client_v221_subscription_setup, id: :pas_client_v221_subscription_setup_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
      end
      group from: :pas_client_v221_workflows, id: :pas_client_v221_workflows_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
      end
      group from: :pas_client_v221_must_support, id: :pas_client_v221_must_support_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
      end
      group from: :pas_client_v221_error_handling_group, id: :pas_client_v221_error_handling_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
      end

      group from: :pas_client_v221_auth_smart,
            required_suite_options: {
              client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
            }
      group from: :pas_client_v221_auth_udap,
            required_suite_options: {
              client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
            }
    end
  end
end
