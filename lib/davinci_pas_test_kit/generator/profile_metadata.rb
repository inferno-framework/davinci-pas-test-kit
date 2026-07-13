module DaVinciPASTestKit
  class Generator
    class ProfileMetadata
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

      # A sorted, bulleted markdown list of this profile's must support elements (slices, elements,
      # extensions, and choices), each line prefixed with `indent` spaces. Shared by the per-profile
      # must support tests and the collapsed attestation tests so both stay in sync with the metadata.
      def must_support_list_string(indent: 8)
        slice_names = must_supports[:slices].map { |slice| slice[:slice_id] }
        element_names = must_supports[:elements].map { |element| "#{resource}.#{element[:path]}" }
        extension_names = must_supports[:extensions].map { |extension| extension[:id] }

        must_supports[:choices]&.each do |choice|
          next unless choice.key?(:paths)

          choice[:paths].each { |path| element_names.delete("#{resource}.#{path}") }
          choice[:extension_ids].each { |id| extension_names.delete(id.to_s) } if choice[:extension_ids].present?

          element_paths = choice[:paths].map { |path| "#{resource}.#{path}" }.join(' or ')
          extension_ids = choice[:extension_ids].join(' or ')

          element_names << "#{element_paths} or #{extension_ids}"
        end

        (slice_names + element_names + extension_names)
          .uniq
          .sort
          .map { |name| "#{' ' * indent}* #{name}" }
          .join("\n")
      end

      def add_test(id:, file_name:)
        self.tests ||= []

        test_metadata = {
          id:,
          file_name:
        }

        tests << test_metadata
      end

      def to_hash
        ATTRIBUTES.each_with_object({}) { |key, hash| hash[key] = send(key) unless send(key).nil? }
      end
    end
  end
end
