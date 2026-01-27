module DaVinciPASTestKit
  class Generator
    class GroupMetadata
      ATTRIBUTES = %i[
        name
        class_name
        version
        reformatted_version
        resource
        conformance_expectation
        profile_url
        profile_name
        profile_version
        title
        short_description
        interactions
        operations
        required_concepts
        must_supports
        mandatory_elements
        bindings
        references
        tests
        id
        file_name
        delayed_references
      ].freeze

      ATTRIBUTES.each { |name| attr_accessor name }

      def initialize(metadata)
        metadata.each do |key, value|
          raise "Unknown attribute #{key}" unless ATTRIBUTES.include? key

          instance_variable_set(:"@#{key}", value)
        end
      end

      def delayed?
        !['Patient', 'Claim', 'ClaimResponse'].include?(resource)
      end

      def add_test(id:, file_name:)
        self.tests ||= []

        test_metadata = {
          id:,
          file_name:
        }

        self.tests << test_metadata
      end

      def to_hash
        ATTRIBUTES.each_with_object({}) { |key, hash| hash[key] = send(key) unless send(key).nil? }
      end
    end
  end
end
