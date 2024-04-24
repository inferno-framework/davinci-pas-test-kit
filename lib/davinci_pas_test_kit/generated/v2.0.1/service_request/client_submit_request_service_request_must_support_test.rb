require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestServiceRequestMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Service Request are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Service Request Profile.
        This test checks all identified instances of the PAS Service Request
        Profile on requests sent by the client to ensure that the following 
        must support elements are observed: 

        * ServiceRequest.code
        * ServiceRequest.extension:coverage
        * ServiceRequest.extension:serviceCodeEnd
        * ServiceRequest.occurrence[x]
        * ServiceRequest.quantity[x]
        * ServiceRequest.subject
      )

      id :pas_client_submit_request_v201_service_request_must_support_test

      def resource_type
        'ServiceRequest'
      end

      def user_input_validation
        false
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:submit_request_resources] ||= {}
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
