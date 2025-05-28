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
      description %(
        The Da Vinci PAS Server Suite validates the conformance of server systems 
        to the STU 2 version of the HL7® FHIR® 
        [Da Vinci Prior Authorization Support Implementation Guide](https://hl7.org/fhir/us/davinci-pas/STU2/).

        These tests are a **DRAFT** intended to allow PAS server implementers to perform 
        preliminary checks of their servers against PAS IG requirements and [provide 
        feedback](https://github.com/inferno-framework/davinci-pas-test-kit/issues) 
        on the tests. Future versions of these tests may validate other 
        requirements and may change the test validation logic.

        The best place to get started is the [Server Testing
        Walkthrough](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Walkthrough),
        which provides a step-by-step guide for running the tests against a client and provides
        an example client implemented in Postman.  Visit the [Server Testing
        Details](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Server-Details)
        documentation for information about technical implementation and known limitations of these tests.

        Inferno will simulate a client and make a series of prior authorization requests to the 
        server under test. Over the course of these requests, Inferno will seek to observe
        conformant handling of PAS requirements, including
        - The ability of the server to use PAS API interactions to communicate 
            - Approval of a prior authorization request
            - Denial of a prior authorization request
            - Pending of a prior authorization request and a subsequent final decision
            - Inability to process a prior authorization request
        - The ability of the server to handle the full scope of data required by PAS, including
            - Ability to process prior auth requests and inquiries with all PAS profiles and all must support elements on those profiles
            - Ability to return responses that demonstrate the use of all PAS profiles and all must support elements on those profiles

        Because the business logic that determines decisions and the elements populated in responses
        Is outside of the PAS specification and will vary between implementers, testers
        are required to provide the requests that Inferno will make to the server.

        All requests and responses will be checked for conformance to the PAS
        IG requirements individually and used in aggregate to determine whether
        required features and functionality are present. HL7® FHIR® resources are 
        validated with the Java validator using `tx.fhir.org` as the terminology server.
      
      %)

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
