require_relative '../../validator_suppressions'
require_relative '../../custom_groups/v2.0.1/pas_error_group'
require_relative '../../custom_groups/v2.0.1/pas_server_subscription_setup'
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

      group from: :pas_server_subscription_setup,
            id: :pas_server_v201_subscription_setup

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
