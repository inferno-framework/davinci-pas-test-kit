require 'pry'
require_relative 'naming'
require_relative 'must_support_check_profiles'

module DaVinciPASTestKit
  class Generator
    class MustSupportTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir)
          submit_request_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.submit_request_group?(group)
          end
          submit_response_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.submit_response_group?(group)
          end
          inquiry_request_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.inquiry_request_group?(group)
          end
          inquiry_response_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.inquiry_response_group?(group)
          end

          submit_request_groups.each do |group|
            new(group, base_output_dir, 'submit_request').generate
            new(group, base_output_dir, 'submit_request', 'client').generate
          end
          submit_response_groups.each { |group| new(group, base_output_dir, 'submit_response').generate }

          inquiry_request_groups.each do |group|
            new(group, base_output_dir, 'inquire_request').generate
            new(group, base_output_dir, 'inquire_request', 'client').generate
          end
          inquiry_response_groups.each { |group| new(group, base_output_dir, 'inquire_response').generate }
        end
      end

      attr_accessor :group_metadata, :base_output_dir, :request_type, :system

      def initialize(group_metadata, base_output_dir, request_type, system = 'server')
        self.group_metadata = group_metadata
        self.base_output_dir = base_output_dir
        self.request_type = request_type
        self.system = system
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'must_support.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
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
        Naming.snake_case_for_profile(group_metadata)
      end

      def test_id
        "pas_#{system}_#{request_type}_#{group_metadata.reformatted_version}_#{profile_identifier}_must_support_test"
      end

      def class_name
        # rubocop:disable Layout/LineLength
        "#{system.capitalize}#{request_type.camelize}#{Naming.upper_camel_case_for_profile(group_metadata)}MustSupportTest"
        # rubocop:enable Layout/LineLength
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

      def resource_collection_string
        'all_scratch_resources'
      end

      def must_support_list_string
        build_must_support_list_string(false)
      end

      def uscdi_list_string
        build_must_support_list_string(true)
      end

      def build_must_support_list_string(uscdi_only)
        slice_names = group_metadata.must_supports[:slices]
          .select { |slice| slice[:uscdi_only].presence == uscdi_only.presence }
          .map { |slice| slice[:name] }

        element_names = group_metadata.must_supports[:elements]
          .select { |element| element[:uscdi_only].presence == uscdi_only.presence }
          .map { |element| "#{resource_type}.#{element[:path]}" }

        extension_names = group_metadata.must_supports[:extensions]
          .select { |extension| extension[:uscdi_only].presence == uscdi_only.presence }
          .map { |extension| extension[:id] }

        group_metadata.must_supports[:choices]&.each do |choice|
          next unless choice[:uscdi_only].presence == uscdi_only.presence && choice.key?(:paths)

          choice[:paths].each { |path| element_names.delete("#{resource_type}.#{path}") }
          choice[:extension_ids].each { |id| extension_names.delete(id.to_s) } if choice[:extension_ids].present?

          element_paths = choice[:paths].map { |path| "#{resource_type}.#{path}" }.join(' or ')
          extension_ids = choice[:extension_ids].map(&:to_s).join(' or ')

          element_names << ("#{element_paths} or #{extension_ids}")
        end

        (slice_names + element_names + extension_names)
          .uniq
          .sort
          .map { |name| "#{' ' * 8}* #{name}" }
          .join("\n")
      end

      def verifies_requirements
        case test_id
        when 'pas_client_inquire_request_v201_claim_inquiry_must_support_test'
          "\n#{' ' * 6}verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@36'\n"
        when 'pas_server_submit_response_v201_claimresponse_must_support_test'
          "\n#{' ' * 6}verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@37', 'hl7.fhir.us.davinci-pas_2.0.1@39',
          #{' ' * 18}'hl7.fhir.us.davinci-pas_2.0.1@110'\n"
        when 'pas_server_inquire_response_v201_claiminquiryresponse_must_support_test'
          "\n#{' ' * 6}verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@38', 'hl7.fhir.us.davinci-pas_2.0.1@40'\n"
        else
          "\n"
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
