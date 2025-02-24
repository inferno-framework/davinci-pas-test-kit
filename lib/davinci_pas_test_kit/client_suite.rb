require 'subscriptions_test_kit'
require_relative 'validator_suppressions'
require_relative 'tags'
require_relative 'urls'
require_relative 'endpoints/claim_endpoint'
require_relative 'endpoints/mock_udap_server'
require_relative 'endpoints/mock_udap_server/registration'
require_relative 'endpoints/mock_udap_server/token'
require_relative 'endpoints/subscription_create_endpoint'
require_relative 'endpoints/subscription_status_endpoint'
require_relative 'custom_groups/v2.0.1/pas_client_approval_group'
require_relative 'custom_groups/v2.0.1/pas_client_denial_group'
require_relative 'custom_groups/v2.0.1/pas_client_pended_group'
require_relative 'custom_groups/v2.0.1/client_tests/pas_client_subscription_create_test'
require_relative 'custom_groups/v2.0.1/client_tests/pas_client_subscription_pas_conformance_test'
require_relative 'generated/v2.0.1/pas_client_submit_must_support_use_case_group'
require_relative 'generated/v2.0.1/pas_client_inquiry_must_support_use_case_group'
require_relative 'custom_groups/v2.0.1/pas_client_registration_group'
require_relative 'custom_groups/v2.0.1/pas_client_auth_group'

module DaVinciPASTestKit
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

    route(:get, UDAP_DISCOVERY_PATH, MockUdapServer.method(:udap_server_metadata))

    suite_endpoint :post, REGISTRATION_PATH, MockUdapServer::RegistrationEndpoint
    suite_endpoint :post, TOKEN_PATH, MockUdapServer::TokenEndpoint

    suite_endpoint :post, SUBMIT_PATH, ClaimEndpoint
    suite_endpoint :post, SESSION_SUBMIT_PATH, ClaimEndpoint
    suite_endpoint :post, INQUIRE_PATH, ClaimEndpoint
    suite_endpoint :post, SESSION_INQUIRE_PATH, ClaimEndpoint
    suite_endpoint :post, FHIR_SUBSCRIPTION_PATH, SubscriptionCreateEndpoint
    suite_endpoint :get, FHIR_SUBSCRIPTION_INSTANCE_PATH, SubscriptionsTestKit::SubscriptionReadEndpoint
    suite_endpoint :post, FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SubscriptionStatusEndpoint
    suite_endpoint :get, FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH, SubscriptionStatusEndpoint
    suite_endpoint :post, FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH, SubscriptionStatusEndpoint

    resume_test_route :get, RESUME_PASS_PATH do |request|
      request.query_parameters['token']
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      request.query_parameters['token']
    end

    group from: :pas_client_v201_registration
    group do
      title 'PAS Client Validation'
      description %(
        These tests perform the functional validation of the client under test.
        For requests to be recognized by Inferno to be part of this test session
        they must include the configured bearer token
        (user provided or generated during the authorization tests)
        in the Authorization HTTP header with prefix "Bearer ".
      )
      group do
        title 'PAS Subscription Setup'
        description %(
          These tests verify that the client can create a Subscription instance
          that will tell the Payer how to notify the client when pended claims
          are updated.
        )
        run_as_group

        test from: :pas_client_v201_subscription_create_test
        test from: :subscriptions_r4_client_subscription_verification
        test from: :pas_client_v201_subscription_pas_conformance_test
        test from: :subscriptions_r4_client_handshake_notification_verification
      end

      group do
        title 'Demonstrate Workflow Support'
        description %(
          The workflow tests validate that the client can participate in complete end-to-end prior
          authorization interactions, initiating requests and reacting appropriately to the
          responses returned.
        )

        input :client_id,
              title: 'Client Id',
              type: 'text',
              optional: true,
              description: %(
                Client Id which the client under test is registered as with the Inferno simulated
                authentication server.
              )
        input :session_url_path,
              title: 'Session-specific URL path extension',
              type: 'text',
              optional: true,
              description: %(
                Ignored if a Client Id is present. If demonstrating PAS
                interactions without authentication, Inferno will use this value to
                setup a session-specific FHIR endpoints to use during these tests.
                If not provided, and no auth configuration is included in the inputs,
                a value will be generated.
              )

        group from: :pas_client_v201_approval_group
        group from: :pas_client_v201_denial_group
        group from: :pas_client_v201_pended_group
      end

      group do
        title 'Demonstrate Element Support'
        description %(
          Demonstrate the ability of the client to support all PAS-defined profiles and the must support elements
          defined in them. This includes

          - the ability to make prior authorization submission and inquiry requests that contain all
            PAS-defined profiles and their must support elements.
          - the ability to receive in responses to those requests all PAS-defined profiles and their
            must support elements and continue the prior authorization workflow as appropriate (not currently
            implemented in these tests).

          Clients under test will be asked to make additional requests to Inferno demonstrating coverage
          of all must support items in the requests. Note that Inferno will consider requests made during
          the workflow group of tests, so only profiles and must support elements not demonstrated during
          those tests need to be submitted as a part of these.
        )

        input :client_id,
              title: 'Client Id',
              type: 'text',
              optional: true,
              description: %(
                Client Id which the client under test is registered as with the Inferno simulated
                authentication server.
              )
        input :session_url_path,
              title: 'Session-specific URL path extension',
              type: 'text',
              optional: true,
              description: %(
                Ignored if a Client Id is present. If demonstrating PAS
                interactions without authentication, Inferno will use this value to
                setup a session-specific FHIR endpoints to use during these tests.
                If not provided, and no auth configuration is included in the inputs,
                a value will be generated.
              )

        group from: :pas_client_v201_submit_must_support_use_case
        group from: :pas_client_v201_inquiry_must_support_use_case
      end
    end
    group from: :pas_client_v201_auth
  end
end
