require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientInquiryRequestCoverageMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Coverage are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Coverage Profile.
        This test checks all identified instances of the PAS Coverage
        Profile on requests sent by the client to ensure that the following 
        must support elements are observed: 

        * Coverage.beneficiary
        * Coverage.identifier
        * Coverage.payor
        * Coverage.relationship
        * Coverage.relationship.coding:X12Code
        * Coverage.status
        * Coverage.subscriber
        * Coverage.subscriberId
      )

      id :pas_client_inquiry_request_v201_coverage_must_support_test

      def resource_type
        'Coverage'
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:inquiry_request_resources] ||= {}
      end

      def resources_of_interest
        collection = tagged_resources(INQUIRE_TAG).presence || all_scratch_resources
        collection.select { |res| res.resourceType == resource_type }
      end

      run do
        perform_must_support_test(resources_of_interest)
        validate_must_support
      end
    end
  end
end
