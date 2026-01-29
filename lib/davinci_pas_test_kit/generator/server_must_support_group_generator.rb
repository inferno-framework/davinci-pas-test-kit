require_relative 'descriptions'

module DaVinciPASTestKit
  class Generator
    class ServerMustSupportGroupGenerator
      class << self
        def generate(ig_metadata, base_server_output_dir)
          new(ig_metadata, base_server_output_dir).generate
        end
      end

      attr_accessor :ig_metadata, :base_output_dir

      def initialize(ig_metadata, base_output_dir)
        self.ig_metadata = ig_metadata
        self.base_output_dir = base_output_dir
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'server_must_support_group.rb.erb'))
      end

      def output
        @output ||= ERB.new(template, trim_mode: '-').result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def class_name
        'PASServerMustSupportGroup'
      end

      def module_name
        "DaVinciPAS#{ig_version_for_id.upcase}"
      end

      def title
        'Demonstrate Element Support'
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def profile_identifier(profile_metadata)
        ig_metadata.snake_case_for_profile(profile_metadata)
      end

      def group_id
        "pas_server_#{ig_version_for_id}_must_support"
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
        ig_metadata.add_use_case_groups(group_id, base_output_file_name)
      end

      def test_id_for_profile(profile_metadata, operation, type)
        "pas_server_#{ig_version_for_id}_#{operation}_#{type}_" \
          "must_support_#{profile_identifier_for_profile(profile_metadata)}"
      end

      def test_file_for_profile(profile_metadata, operation, type)
        profile_id = profile_identifier_for_profile(profile_metadata)
        File.join(profile_id, "server_#{operation}_#{type}_must_support_#{profile_id}_test")
      end

      def profile_identifier_for_profile(profile_metadata)
        ig_metadata.snake_case_for_profile(profile_metadata)
      end

      def profile_test_ids(operation, type)
        profiles_for(operation, type).map { |profile_metadata| test_id_for_profile(profile_metadata, operation, type) }
      end

      def profile_test_files(operation, type)
        profiles_for(operation, type).map do |profile_metadata|
          test_file_for_profile(profile_metadata, operation, type)
        end
      end

      def profiles_for(operation, type)
        ig_metadata.profiles.select do |profile|
          case "#{operation}_#{type}"
          when 'submit_request'
            MustSupportCheckProfiles.submit_request_profile?(profile) && !MustSupportCheckProfiles.request_profile?(profile)
          when 'submit_response'
            MustSupportCheckProfiles.submit_response_profile?(profile)
          when 'inquire_request'
            MustSupportCheckProfiles.inquire_request_profile?(profile)
          when 'inquire_response'
            MustSupportCheckProfiles.inquire_response_profile?(profile)
          end
        end
      end

      def request_profiles
        ig_metadata.profiles.select { |profile_metadata| MustSupportCheckProfiles.request_profile?(profile_metadata) }
      end

      def verifies_requirements
        case ig_metadata.ig_version
        when 'v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@33']
        end
      end

      def verifies_must_support_requirements(operation, type)
        case "#{operation}_#{type}_#{ig_metadata.ig_version}"
        when 'submit_request_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@35']
        when 'inquire_request_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@36']
        end
      end

      def description
        <<~DESCRIPTION
          Demonstrate the ability of the server to support all PAS-defined profiles
          and the must support elements defined in them. This includes

          - the ability to respond to prior authorization submission and inquiry
            requests that contain all PAS-defined profiles and their must support
            elements.
          - the ability to include in those responses all PAS-defined profiles
            and their must support elements.

          In order to allow Inferno to observe and validate these criteria, testers
          are required to provide a set of `$submit` and `$inquire` requests that
          collectively both themselves contain and elicit server responses that contain
          all PAS-defined profiles and their must support elements.
        DESCRIPTION
      end

      def subgroup_description(operation)
        <<~DESCRIPTION
          Check that the provided `$#{operation}` requests both themselves contain
          and elicit server responses that contain all PAS-defined profiles
          and their must support elements.

          For `$#{operation}` requests, this includes the following profiles:

          #{Descriptions.profile_links_list(profiles_for(operation, 'request'), request_profiles: operation == 'submit' ? request_profiles : nil)}

          For `$#{operation}` responses, this includes the following profiles (NOTE: request-specific
          profiles that may be echoed from `$#{operation}` requests, such as the Claim instance or request instances,
          are not currently checked):

          #{Descriptions.profile_links_list(profiles_for(operation, 'response'))}
        DESCRIPTION
      end
    end
  end
end
