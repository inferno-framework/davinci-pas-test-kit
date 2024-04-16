require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquiryRequestPasInquiryRequestBundleMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Inquiry Request Bundle are observed across all instances submitted'
      description %(
        
        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Inquiry Request Bundle Profile.
        This test checks all identified instances of the PAS Inquiry Request Bundle
        Profile on requests sent to the server to ensure that the following 
        must support elements are observed:

        * Bundle.entry
        * Bundle.entry.fullUrl
        * Bundle.entry.resource
        * Bundle.entry:Claim
        * Bundle.identifier
        * Bundle.timestamp
      )

      id :pas_server_inquiry_request_v201_pas_inquiry_request_bundle_must_support_test

      def resource_type
        'Bundle'
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:inquire_request_resources] ||= {}
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
