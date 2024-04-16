require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerSubmitResponseCommunicationRequestMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS CommunicationRequest are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS CommunicationRequest Profile.
        This test checks all identified instances of the PAS CommunicationRequest
        Profile on responses returned by the server to ensure that the following 
        must support elements are observed:

        * CommunicationRequest.category
        * CommunicationRequest.identifier
        * CommunicationRequest.medium
        * CommunicationRequest.payload
        * CommunicationRequest.payload.content[x]
        * CommunicationRequest.payload.extension:communicatedDiagnosis
        * CommunicationRequest.payload.extension:contentModifier
        * CommunicationRequest.payload.extension:serviceLineNumber
        * CommunicationRequest.recipient
        * CommunicationRequest.requester
        * CommunicationRequest.sender
      )

      id :pas_server_submit_response_v201_communication_request_must_support_test

      def resource_type
        'CommunicationRequest'
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:submit_response_resources] ||= {}
      end

      def resources_of_interest
        collection = tagged_resources(SUBMIT_TAG).presence || all_scratch_resources
        collection.select { |res| res.resourceType == resource_type }
      end

      run do
        perform_must_support_test(resources_of_interest)
        validate_must_support
      end
    end
  end
end
