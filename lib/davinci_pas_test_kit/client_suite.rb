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
require_relative 'custom_groups/v2.0.1/pas_client_options'
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
      description %(
        The Da Vinci PAS Test Kit Client Suite validates the conformance of client
        systems to the STU 2 version of the HL7® FHIR®
        [Da Vinci Prior Authorization Support Implementation Guide](https://hl7.org/fhir/us/davinci-pas/STU2/).

        These tests are a **DRAFT** intended to allow PAS client implementers to perform
        preliminary checks of their clients against PAS IG requirements and [provide
        feedback](https://github.com/inferno-framework/davinci-pas-test-kit/issues)
        on the tests. Future versions of these tests may validate other
        requirements and may change the test validation logic.

        The best place to get started is the [Client Testing
        Walkthrough](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Walkthrough)],
        which provides a step-by-step guide for running the tests against a client and provides
        an example client implemented in Postman.  Visit the [Client Testing
        Details](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Details)
        documentation for information about technical implementation and known limitations of these tests.

        In this test suite, Inferno simulates a PAS server for the client under test to
        interact with. The client will be expected to initiate requests to the server
        and demonstrate its ability to react to the returned responses. Over the course
        of these interactions, Inferno will seek to observe conformant handling of PAS
        requirements, including:
        - The ability of the client to initiate a prior authorization submission and react to
            - The approval of the request
            - The denial of the request
            - The pending of the request and a subsequent notification that a final decision was made
        - The ability of the client to provide data covering the full scope of required by PAS, including
            - The ability to send prior auth requests and inquiries with all PAS
              profiles and all must support elements on those profiles
            - The ability to handle responses that contain all PAS profiles and all must support elements on those
              profiles (not included in the current version of these tests)

        All requests and responses will be checked for conformance to the PAS
        IG requirements individually and used in aggregate to determine whether
        required features and functionality are present. HL7® FHIR® resources are
        validated with the Java validator using `tx.fhir.org` as the terminology server.
      )

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
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v201_workflows, id: :pas_client_v201_workflows_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v201_must_support, id: :pas_client_v201_must_support_smart do
        required_suite_options client_type: PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end

      # UDAP test groups (with :session_url_path input removed)
      group from: :pas_client_v201_subscription_setup, id: :pas_client_v201_subscription_setup_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v201_workflows, id: :pas_client_v201_workflows_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end
      group from: :pas_client_v201_must_support, id: :pas_client_v201_must_support_udap do
        required_suite_options client_type: PASClientOptions::UDAP_CLIENT_CREDENTIALS
        PASClientOptions.recursive_remove_input(self, :session_url_path)
        config(inputs: { client_id: { optional: false } })
      end

      # Dedicated Endpoints test groups (with :client_id input removed)
      group from: :pas_client_v201_subscription_setup, id: :pas_client_v201_subscription_setup_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
      end
      group from: :pas_client_v201_workflows, id: :pas_client_v201_workflows_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
      end
      group from: :pas_client_v201_must_support, id: :pas_client_v201_must_support_no_auth do
        required_suite_options client_type: PASClientOptions::OTHER_AUTH
        PASClientOptions.recursive_remove_input(self, :client_id)
        config(inputs: { session_url_path: { optional: false } })
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
