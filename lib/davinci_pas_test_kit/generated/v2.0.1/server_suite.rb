require 'subscriptions_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../../validator_suppressions'
require_relative '../../custom_groups/v2.0.1/pas_error_group'
require_relative '../../custom_groups/v2.0.1/pas_server_subscription_input_conformance'
require_relative 'pas_server_approval_use_case_group'
require_relative 'pas_server_denial_use_case_group'
require_relative 'pas_server_pended_use_case_group'
require_relative 'pas_server_must_support_use_case_group'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSuite < Inferno::TestSuite
      id :davinci_pas_server_suite_v201
      title 'Da Vinci PAS Server Suite v2.0.1'
      description File.read(File.join(__dir__, '..', '..', 'docs', 'server_suite_description_v201.md'))

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
          SUPPRESSED_MESSAGES.match?(message.message.sub(/\A\S+: \S+: /, '')) ||
            message.message.downcase.include?('x12')
        end
      end

      input :server_endpoint,
            title: 'FHIR Server Endpoint URL',
            description: 'Insert the FHIR server endpoint URL for PAS'

      input :smart_credentials,
            title: 'OAuth Credentials',
            type: :auth_info,
            options: {
              mode: 'access',
              components: [
                {
                  name: :auth_type,
                  default: 'backend_services'
                }
              ]
            },
            optional: true

      fhir_client do
        url :server_endpoint
        auth_info :smart_credentials
      end

      resume_test_route :get, RESUME_SKIP_PATH, result: 'skip' do |request|
        request.query_parameters['token']
      end

      # Used for attestation experiment - see pas_claim_response_decision_test.rb
      # resume_test_route :get, RESUME_PASS_PATH do |request|
      #   request.query_parameters['token']
      # end
      #
      # resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      #   request.query_parameters['token']
      # end

      group 'Subscription Setup' do
        description %(
          The Subscription Setup tests verify that the server supports creation of a rest-hook Subscription. The
          Subscription instance created in these tests will be used for a notification in the pended workflow tests
          later.
        )
        config inputs: { url: { name: :server_endpoint } }
        input_order :server_endpoint, :smart_credentials, :access_token, :subscription_resource
        verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@141'
        run_as_group

        test from: :subscriptions_r4_server_subscription_conformance do
             input :subscription_resource,
                   title: 'Pended Prior Authorization Subscription',
                   description: %(
                     A Subscription resource in JSON format that Inferno will send to the server under test so that it
                     can demonstrate its ability to notify Inferno when pended prior authorization requests have been
                     updated. The instance must be conformant to the R4/B Topic-Based Subscription profile. Inferno may
                     modify the Subscription before submission, e.g., to point to Inferno's notification endpoint.
                   )
        end
        test from: :pas_server_subscription_input_conformance
        test from: :subscriptions_r4_server_notification_delivery,
             title: 'Send Subscription and Receive Handshake Notification from Server',
             description: %(
               This test sends a request to create the Subscription resource to the Subscriptions Backport FHIR Server.
               If successful, it then waits for a handshake
               [notification](https://hl7.org/fhir/uv/subscriptions-backport/STU1.1/notifications.html#notifications).
               Other types of notifications, including heartbeat and event notifications, will be accepted by Inferno
               but ignored by this test group.
             )
        test from: :subscriptions_r4_server_creation_response_conformance
        test from: :subscriptions_r4_server_handshake_conformance
      end

      group 'Demonstrate Workflow Support' do
        description %(
          The workflow tests validate that the server can participate in complete
          end-to-end prior authorization interactions, returning responses that are
          conformant and also contain the correct codes.
        )
        
        group from: :pas_server_v201_approval_use_case
        group from: :pas_server_v201_denial_use_case
        group from: :pas_server_v201_pended_use_case
      end
      group from: :pas_server_v201_must_support_use_case
      group from: :pas_v201_error_group
    end
  end
end
