require_relative 'must_support_check_profiles'
require_relative 'descriptions'

module DaVinciPASTestKit
  class Generator
    class ClientMustSupportGroupGenerator
      class << self
        def generate(ig_metadata, base_client_output_dir)
          submit_request_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.submit_request_group?(group)
          end
          new(ig_metadata, 'submit', submit_request_groups, base_client_output_dir).generate

          inquire_request_groups = ig_metadata.groups.select do |group|
            MustSupportCheckProfiles.inquire_request_group?(group)
          end
          new(ig_metadata, 'inquire', inquire_request_groups, base_client_output_dir).generate
        end
      end

      attr_accessor :ig_metadata, :operation, :groups, :base_output_dir, :type

      def initialize(ig_metadata, operation, groups, base_output_dir)
        self.ig_metadata = ig_metadata
        self.operation = operation
        self.groups = groups
        self.base_output_dir = base_output_dir
        self.type = 'request' # TODO: currently only request must supports checked for client. Add responses?
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'client_must_support_group.rb.erb'))
      end

      def output
        @output ||= ERB.new(template, trim_mode: '-').result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def class_name
        "PASClient#{operation.camelize}MustSupportGroup"
      end

      def module_name
        "DaVinciPAS#{ig_version_for_id.upcase}"
      end

      def title
        return 'Submit Request Must Support' if operation == 'submit'

        'Inquiry Request Must Support'
      end

      def request_type
        "#{operation}_#{type}"
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def profile_identifier(group_metadata)
        ig_metadata.snake_case_for_profile(group_metadata)
      end

      def group_id
        "pas_client_#{ig_version_for_id}_#{operation}_must_support"
      end

      def ig_version
        ig_metadata.ig_version
      end

      def ig_version_for_id
        ig_metadata.reformatted_version
      end

      def generate
        FileUtils.mkdir_p(base_output_dir)
        File.write(output_file_name, output)
      end

      def required_groups
        @required_groups = groups.reject { |group_metadata| MustSupportCheckProfiles.request_group?(group_metadata) }
      end

      def request_groups
        @request_groups = groups.select { |group_metadata| MustSupportCheckProfiles.request_group?(group_metadata) }
      end

      def test_id_for_group(group_metadata)
        "pas_client_#{ig_metadata.reformatted_version}_#{request_type}_" \
          "must_support_#{profile_identifier_for_group(group_metadata)}"
      end

      def test_file_for_group(group_metadata)
        profile_id = profile_identifier_for_group(group_metadata)
        File.join(profile_id, "client_#{request_type}_must_support_#{profile_id}_test")
      end

      def profile_identifier_for_group(group_metadata)
        ig_metadata.snake_case_for_profile(group_metadata)
      end

      def profile_test_ids
        required_groups.map { |group_metadata| test_id_for_group(group_metadata) }
      end

      def profile_test_files
        required_groups.map { |group_metadata| test_file_for_group(group_metadata) }
      end

      def description
        <<~DESCRIPTION
          Check that the client can demonstrate `$#{operation}` requests that contain
          all PAS-defined profiles and their must support elements.

          For `$#{operation}` requests, this includes the following profiles:

          #{Descriptions.profile_links_list(required_groups, request_groups:)}
        DESCRIPTION
      end
    end
  end
end
