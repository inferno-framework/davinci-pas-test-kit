require_relative 'ig_metadata'
require_relative 'group_metadata_extractor'
require 'pry'
module DaVinciPASTestKit
  class Generator
    class IGMetadataExtractor
      attr_accessor :ig_resources, :metadata

      def initialize(ig_resources)
        self.ig_resources = ig_resources
        self.metadata = IGMetadata.new
      end

      def extract
        add_metadata_from_ig
        add_metadata_from_resources
        metadata
      end

      def add_metadata_from_ig
        metadata.ig_version = "v#{ig_resources.ig.version}"
      end

      def resources_in_capability_statement
        # TODO: uncomment bellow when PAS IG will have a solid capability statement.
        # ig_resources.capability_statement.rest.first.resource

        # Work around for the code above to extract the IG supported profiles/resources
        resources = []
        ig_resources.base_resources_and_supported_profiles.each do |k, v|
          resource = FHIR::CapabilityStatement::Rest::Resource.new(
            type: k,
            supportedProfile: v,
            operation: k == 'Claim' ? [{ name: '$submit' }, { name: '$inquire' }] : []
          )
          resources << resource
        end

        resources
      end

      def add_metadata_from_resources
        metadata.groups =
          resources_in_capability_statement.flat_map do |resource|
            resource.supportedProfile&.map do |supported_profile|
              GroupMetadataExtractor.new(resource, supported_profile, metadata, ig_resources).group_metadata
            end
          end

        metadata.postprocess_groups(ig_resources)
      end
    end
  end
end
