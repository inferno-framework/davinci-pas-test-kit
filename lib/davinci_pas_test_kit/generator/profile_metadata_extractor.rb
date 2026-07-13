require_relative 'profile_metadata'
require_relative 'ig_metadata'
require_relative 'terminology_binding_metadata_extractor'
require_relative 'pas_must_support_metadata_extractor'

module DaVinciPASTestKit
  class Generator
    class ProfileMetadataExtractor
      attr_accessor :resource_capabilities, :profile_url, :ig_metadata, :ig_resources

      def initialize(resource_capabilities, profile_url, ig_metadata, ig_resources)
        self.resource_capabilities = resource_capabilities
        self.profile_url = profile_url
        self.ig_metadata = ig_metadata
        self.ig_resources = ig_resources
      end

      def profile_metadata
        @profile_metadata ||=
          ProfileMetadata.new(profile_metadata_hash)
      end

      def profile_metadata_hash
        @profile_metadata_hash ||=
          {
            name:,
            class_name:,
            version:,
            reformatted_version:,
            resource:,
            conformance_expectation:,
            profile_url:,
            profile_name:,
            profile_version:,
            title:,
            short_description:,
            interactions:,
            operations:,
            required_concepts:,
            must_supports:,
            mandatory_elements:,
            bindings:,
            references:
          }

        @profile_metadata_hash
      end

      def profile
        @profile ||= ig_resources.profile_by_url(profile_url)
      end

      def profile_elements
        @profile_elements ||= profile.snapshot.element
      end

      def base_name
        profile_url.split('StructureDefinition/').last
      end

      def name
        base_name.tr('-', '_')
      end

      def class_name
        base_name
          .split('-')
          .map(&:capitalize)
          .join
          .gsub('PAS', "PAS#{ig_metadata.reformatted_version}")
          .concat('Sequence')
      end

      def version
        ig_metadata.ig_version
      end

      def reformatted_version
        ig_metadata.reformatted_version
      end

      def resource
        profile.type
      end

      def conformance_expectation
        return unless resource_capabilities.present?

        resource_capabilities.extension&.first&.valueCode
      end

      def profile_name
        profile.title.gsub('  ', ' ')
      end

      def profile_version
        profile.version
      end

      def title
        profile.title.gsub(/PAS\s*/, '').gsub(/\s*Profile/, '').strip
      end

      def short_description
        "Verify support for the server capabilities required by the #{profile_name}."
      end

      def interactions
        @interactions ||=
          resource_capabilities.interaction.map do |interaction|
            {
              code: interaction.code,
              # TODO: fix expectation extension finding
              expectation: interaction.present? ? interaction.extension&.first&.valueCode : nil
            }
          end
      end

      def operations
        @operations ||=
          resource_capabilities.operation.map do |operation|
            {
              code: operation.name,
              # TODO: fix expectation extension finding
              expectation: operation.present? ? operation.extension&.first&.valueCode : nil
            }
          end
      end

      def required_concepts
        return [] if resource == 'Observation'

        profile_elements
          .select { |element| element.type&.any? { |type| type.code == 'CodeableConcept' } }
          .select { |element| element.binding&.strength == 'required' }
          .map { |element| element.path.gsub("#{resource}.", '').gsub('[x]', 'CodeableConcept') }
      end

      def terminology_binding_metadata_extractor
        @terminology_binding_metadata_extractor ||=
          TerminologyBindingMetadataExtractor.new(profile_elements, ig_resources, resource)
      end

      def bindings
        @bindings ||=
          terminology_binding_metadata_extractor.terminology_bindings
      end

      def must_support_metadata_extractor
        @must_support_metadata_extractor ||=
          PASMustSupportMetadataExtractor.new(profile_elements, profile, resource, ig_resources)
      end

      def must_supports
        # binding.pry if profile_url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim-inquiry'
        @must_supports ||=
          must_support_metadata_extractor.must_supports
      end

      def mandatory_elements
        @mandatory_elements ||=
          profile_elements
            .select { |element| element.min.positive? }
            .map(&:path)
            .uniq
      end

      def references
        @references ||=
          profile_elements
            .select { |element| element.type&.first&.code == 'Reference' }
            .map do |reference_definition|
            {
              path: reference_definition.path,
              profiles: reference_definition.type.first.targetProfile
            }
          end
      end
    end
  end
end
