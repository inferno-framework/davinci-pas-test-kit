require 'subscriptions_test_kit'
require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative 'validator_suppressions'
require_relative 'tags'
require_relative 'urls'
require_relative 'endpoints/claim_endpoint'
require_relative 'endpoints/token_endpoint'
require_relative 'endpoints/subscription_create_endpoint'
require_relative 'endpoints/subscription_status_endpoint'
require_relative 'custom_groups/v2.0.1/client_options'
require_relative 'custom_groups/v2.0.1/pas_client_workflows_group'
require_relative 'custom_groups/v2.0.1/pas_client_must_support_group'
require_relative 'custom_groups/v2.0.1/pas_client_subscription_setup_group'
require_relative 'custom_groups/v2.0.1/pas_client_registration_group'
require_relative 'custom_groups/v2.0.1/pas_client_auth_smart_group'
require_relative 'custom_groups/v2.0.1/pas_client_auth_udap_group'
require_relative 'descriptions'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSuite < Inferno::TestSuite
      id :davinci_pas_client_suite_v201
      title 'Da Vinci PAS Client Suite v2.0.1'
      description File.read(File.join(__dir__, 'docs', 'client_suite_description_v201.md'))

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
          url: 'https://hl7.org/fhir/us/davinci-pas/STU2/'
        }
      ]

      fhir_resource_validator do
        igs 'hl7.fhir.us.davinci-pas#2.0.1'

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
                       label: 'Other',
                       value: PASClientOptions::DEDICATED_ENDPOINTS
                     }
                   ]

      route(:get, UDAPSecurityTestKit::UDAP_DISCOVERY_PATH, lambda { |_env|
        UDAPSecurityTestKit::MockUDAPServer.udap_server_metadata(id)
      })
      route(:get, SMARTAppLaunch::SMART_DISCOVERY_PATH, lambda { |_env|
        SMARTAppLaunch::MockSMARTServer.smart_server_metadata(id)
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

      resume_test_route :get, RESUME_PASS_PATH do |request|
        request.query_parameters['token']
      end

      resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
        request.query_parameters['token']
      end

      group from: :pas_client_v201_registration

      # SMART test groups (with :session_url_path input removed)
      group from: :pas_client_v201_subscription_setup, id: :pas_client_v201_subscription_setup_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
      end
      group from: :pas_client_v201_workflows, id: :pas_client_v201_workflows_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
      end
      group from: :pas_client_v201_must_support, id: :pas_client_v201_must_support_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
      end

      # UDAP test groups (with :session_url_path input removed)
      group from: :pas_client_v201_subscription_setup, id: :pas_client_v201_subscription_setup_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
      end
      group from: :pas_client_v201_workflows, id: :pas_client_v201_workflows_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
      end
      group from: :pas_client_v201_must_support, id: :pas_client_v201_must_support_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
      end

      # Dedicated Endpoints test groups (with :client_id input removed)
      group from: :pas_client_v201_subscription_setup, id: :pas_client_v201_subscription_setup_no_auth do
        required_suite_options client_type: PASClientOptions::DEDICATED_ENDPOINTS
        PASClientOptions.recursive_remove_input(self, :client_id)
      end
      group from: :pas_client_v201_workflows, id: :pas_client_v201_workflows_no_auth do
        required_suite_options client_type: PASClientOptions::DEDICATED_ENDPOINTS
        PASClientOptions.recursive_remove_input(self, :client_id)
      end
      group from: :pas_client_v201_must_support, id: :pas_client_v201_must_support_no_auth do
        required_suite_options client_type: PASClientOptions::DEDICATED_ENDPOINTS
        PASClientOptions.recursive_remove_input(self, :client_id)
      end

      group from: :pas_client_v201_auth_smart,
            required_suite_options: {
              client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
            }
      group from: :pas_client_v201_auth_udap,
            required_suite_options: {
              client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
            }
    end
  end
end
