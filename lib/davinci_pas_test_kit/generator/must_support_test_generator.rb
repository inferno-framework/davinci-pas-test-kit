require_relative 'must_support_check_profiles'

module DaVinciPASTestKit
  class Generator
    class MustSupportTestGenerator
      class << self
        def generate(ig_metadata, base_server_output_dir, base_client_output_dir)
          submit_request_groups =
            ig_metadata.groups.select { |group| MustSupportCheckProfiles.submit_request_group?(group) }
              .reject { |group| MustSupportCheckProfiles.request_group?(group) }
          submit_response_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.submit_response_group?(group)
          end
          inquiry_request_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.inquire_request_group?(group)
          end
          inquiry_response_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.inquire_response_group?(group)
          end

          submit_request_groups.each do |group|
            new(ig_metadata, group, base_server_output_dir, 'request', 'submit').generate
            new(ig_metadata, group, base_client_output_dir, 'request', 'submit', 'client').generate
          end
          submit_response_groups.each do |group|
            new(ig_metadata, group, base_server_output_dir, 'response', 'submit').generate
          end

          inquiry_request_groups.each do |group|
            new(ig_metadata, group, base_server_output_dir, 'request', 'inquire').generate
            new(ig_metadata, group, base_client_output_dir, 'request', 'inquire', 'client').generate
          end
          inquiry_response_groups.each do |group|
            new(ig_metadata, group, base_server_output_dir, 'response', 'inquire').generate
          end
        end
      end

      attr_accessor :ig_metadata, :group_metadata, :base_output_dir, :type, :operation, :system

      def initialize(ig_metadata, group_metadata, base_output_dir, type, operation, system = 'server')
        self.ig_metadata = ig_metadata
        self.group_metadata = group_metadata
        self.base_output_dir = base_output_dir
        self.type = type
        self.operation = operation
        self.system = system
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'must_support.rb.erb'))
      end

      def output
        @output ||= ERB.new(template, trim_mode: '-').result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def output_file_directory
        File.join(base_output_dir, profile_identifier)
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def read_interaction
        self.class.read_interaction(group_metadata)
      end

      def profile_identifier
        ig_metadata.snake_case_for_profile(group_metadata)
      end

      def request_type
        "#{operation}_#{type}"
      end

      def test_id
        "pas_#{system}_#{group_metadata.reformatted_version}_#{request_type}_must_support_#{profile_identifier}"
      end

      def class_name
        "#{system.capitalize}#{request_type.camelize}MustSupport" \
          "#{ig_metadata.upper_camel_case_for_profile(group_metadata)}Test"
      end

      def module_name
        "DaVinciPAS#{group_metadata.reformatted_version.upcase}"
      end

      def resource_type
        group_metadata.resource
      end

      def profile_name
        group_metadata.profile_name
      end

      def must_support_list_string
        build_must_support_list_string
      end

      def build_must_support_list_string
        slice_names = group_metadata.must_supports[:slices]
          .map { |slice| slice[:slice_id] }

        element_names = group_metadata.must_supports[:elements]
          .map { |element| "#{resource_type}.#{element[:path]}" }

        extension_names = group_metadata.must_supports[:extensions]
          .map { |extension| extension[:id] }

        group_metadata.must_supports[:choices]&.each do |choice|
          next unless choice.key?(:paths)

          choice[:paths].each { |path| element_names.delete("#{resource_type}.#{path}") }
          choice[:extension_ids].each { |id| extension_names.delete(id.to_s) } if choice[:extension_ids].present?

          element_paths = choice[:paths].map { |path| "#{resource_type}.#{path}" }.join(' or ')
          extension_ids = choice[:extension_ids].map(&:to_s).join(' or ')

          element_names << "#{element_paths} or #{extension_ids}"
        end

        (slice_names + element_names + extension_names)
          .uniq
          .sort
          .map { |name| "#{' ' * 8}* #{name}" }
          .join("\n")
      end

      def verifies_requirements
        case "#{system}_#{operation}_#{type}_#{ig_metadata.ig_version}"
        when 'server_submit_response_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@37', 'hl7.fhir.us.davinci-pas_2.0.1@110']
        when 'server_inquire_response_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@38']
        end
      end

      def optional?
        MustSupportCheckProfiles.optional_group?(group_metadata)
      end

      def generate
        FileUtils.mkdir_p(output_file_directory)
        File.write(output_file_name, output)

        group_metadata.add_test(
          id: test_id,
          file_name: base_output_file_name
        )
      end
    end
  end
end
