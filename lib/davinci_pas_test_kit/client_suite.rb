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
require_relative 'custom_groups/v2.0.1/pas_client_approval_group'
require_relative 'custom_groups/v2.0.1/pas_client_denial_group'
require_relative 'custom_groups/v2.0.1/pas_client_pended_group'
require_relative 'custom_groups/v2.0.1/pas_client_subscription_setup_group'
require_relative 'generated/v2.0.1/pas_client_submit_must_support_use_case_group'
require_relative 'generated/v2.0.1/pas_client_inquiry_must_support_use_case_group'
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

      group from: :pas_client_v201_subscription_setup

      group do
        title 'PAS Workflows'
        description %(
        The workflow tests verify that the client can participate in complete end-to-end prior
        authorization interactions, initiating requests and reacting appropriately to the
        responses returned.
      )

        group from: :pas_client_v201_approval_group
        group from: :pas_client_v201_denial_group
        group from: :pas_client_v201_pended_group
      end

      group do
        title 'Must Support Elements'
        description %(
        During these tests, the client will show that it supports all PAS-defined profiles and the must support
        elements defined in them. This includes

        - The ability to make prior authorization submission and inquiry requests that contain all
          PAS-defined profiles and their must support elements.
        - The ability to receive in responses to those requests all PAS-defined profiles and their
          must support elements and continue the prior authorization workflow as appropriate (not currently
          implemented in these tests).

        Clients under test will be asked to make additional requests to Inferno demonstrating coverage
        of all must support items in the requests. Note that Inferno will consider requests made during
        the workflow group of tests, so only profiles and must support elements not demonstrated during
        those tests need to be submitted as a part of these.
      )

        group from: :pas_client_v201_submit_must_support_use_case
        group from: :pas_client_v201_inquiry_must_support_use_case
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
