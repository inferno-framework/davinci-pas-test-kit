require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitResponseClaimresponseMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Claim Response are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Claim Response Profile.
        This test checks all identified instances of the PAS Claim Response
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * ClaimResponse.communicationRequest
        * ClaimResponse.created
        * ClaimResponse.error
        * ClaimResponse.error.code
        * ClaimResponse.error.extension:errorElement
        * ClaimResponse.error.extension:errorPath
        * ClaimResponse.error.extension:followupAction
        * ClaimResponse.identifier
        * ClaimResponse.insurer
        * ClaimResponse.item
        * ClaimResponse.item.adjudication
        * ClaimResponse.item.adjudication.extension:reviewAction
        * ClaimResponse.item.extension:administrationReferenceNumber
        * ClaimResponse.item.extension:authorizedItemDetail
        * ClaimResponse.item.extension:authorizedProvider
        * ClaimResponse.item.extension:communicatedDiagnosis
        * ClaimResponse.item.extension:itemTraceNumber
        * ClaimResponse.item.extension:preAuthIssueDate
        * ClaimResponse.item.extension:preAuthPeriod
        * ClaimResponse.item.extension:previousAuthorizationNumber
        * ClaimResponse.item.extension:requestedServiceDate
        * ClaimResponse.item.noteNumber
        * ClaimResponse.outcome
        * ClaimResponse.patient
        * ClaimResponse.preAuthPeriod
        * ClaimResponse.request
        * ClaimResponse.requestor
        * ClaimResponse.status
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@37', 'hl7.fhir.us.davinci-pas_2.0.1@39',
                            'hl7.fhir.us.davinci-pas_2.0.1@110'

      id :pas_server_submit_response_v201_claimresponse_must_support_test

      def resource_type
        'ClaimResponse'
      end

      def user_input_validation
        false
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        # The scratch key in MS test should be the same as the scratch key in the validation test for a given profile.
        scratch[:submit_response_resources] ||= {}
      end

      def resources_of_interest
        collection = tagged_resources(SUBMIT_TAG).presence || all_scratch_resources
        collection.select { |res| res.resourceType == resource_type }
      end

      run do
        perform_must_support_test(resources_of_interest)
        validate_must_support(user_input_validation)
      end
    end
  end
end
