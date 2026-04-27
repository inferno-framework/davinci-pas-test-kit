require_relative 'must_support_target_profiles'
require_relative 'descriptions'

module DaVinciPASTestKit
  class Generator
    class ClientMustSupportGroupGenerator
      class << self
        def generate(ig_metadata, base_client_output_dir)
          submit_request_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.submit_request_profile?(profile)
          end
          new(ig_metadata, 'submit', submit_request_profiles, base_client_output_dir).generate

          submit_response_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.submit_response_profile?(profile)
          end
          new(ig_metadata, 'submit', submit_response_profiles, base_client_output_dir, 'response').generate

          inquire_request_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.inquire_request_profile?(profile)
          end
          new(ig_metadata, 'inquire', inquire_request_profiles, base_client_output_dir).generate

          inquire_response_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.inquire_response_profile?(profile)
          end
          new(ig_metadata, 'inquire', inquire_response_profiles, base_client_output_dir, 'response').generate
        end
      end

      attr_accessor :ig_metadata, :operation, :profiles, :base_output_dir, :type

      def initialize(ig_metadata, operation, profiles, base_output_dir, type = 'request')
        self.ig_metadata = ig_metadata
        self.operation = operation
        self.profiles = profiles
        self.base_output_dir = base_output_dir
        self.type = type
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', template_file_name))
      end

      def template_file_name
        type == 'response' ? 'client_must_support_response_group.rb.erb' : 'client_must_support_group.rb.erb'
      end

      def output
        @output ||= ERB.new(template, trim_mode: '-').result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def class_name
        if type == 'response'
          "PASClient#{operation.camelize}ResponseMustSupportGroup"
        else
          "PASClient#{operation.camelize}MustSupportGroup"
        end
      end

      def module_name
        "DaVinciPAS#{ig_version_for_id.upcase}"
      end

      def title
        if type == 'response'
          return 'Submit Response Must Support' if operation == 'submit'

          'Inquiry Response Must Support'
        else
          return 'Submit Request Must Support' if operation == 'submit'

          'Inquiry Request Must Support'
        end
      end

      def request_type
        "#{operation}_#{type}"
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def profile_identifier(profile_metadata)
        ig_metadata.snake_case_for_profile(profile_metadata)
      end

      def group_id
        if type == 'response'
          "pas_client_#{ig_version_for_id}_#{operation}_response_must_support"
        else
          "pas_client_#{ig_version_for_id}_#{operation}_must_support"
        end
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

      def required_profiles
        @required_profiles = profiles.reject do |profile_metadata|
          MustSupportTargetProfiles.request_profile?(profile_metadata)
        end
      end

      def request_profiles
        @request_profiles = profiles.select do |profile_metadata|
          MustSupportTargetProfiles.request_profile?(profile_metadata)
        end
      end

      def test_id_for_profile(profile_metadata)
        "pas_client_#{ig_metadata.reformatted_version}_#{request_type}_" \
          "must_support_#{profile_identifier_for_profile(profile_metadata)}"
      end

      def test_file_for_profile(profile_metadata)
        profile_id = profile_identifier_for_profile(profile_metadata)
        File.join(profile_id, "client_#{request_type}_must_support_#{profile_id}_test")
      end

      def profile_identifier_for_profile(profile_metadata)
        ig_metadata.snake_case_for_profile(profile_metadata)
      end

      def profile_test_ids
        target_profiles = type == 'response' ? profiles : required_profiles
        target_profiles.map { |profile_metadata| test_id_for_profile(profile_metadata) }
      end

      def profile_test_files
        target_profiles = type == 'response' ? profiles : required_profiles
        target_profiles.map { |profile_metadata| test_file_for_profile(profile_metadata) }
      end

      def verifies_requirements
        case "#{operation}_#{ig_version}"
        when 'submit_v2.0.1'
          return nil if type == 'response'

          ['hl7.fhir.us.davinci-pas_2.0.1@58', 'hl7.fhir.us.davinci-pas_2.0.1@62',
           'hl7.fhir.us.davinci-pas_2.0.1@70', 'hl7.fhir.us.davinci-pas_2.0.1@202']
        end
      end

      def description
        if type == 'response'
          <<~DESCRIPTION
            Check that `$#{operation}` responses provided to the client contain
            all PAS-defined profiles and their must support elements.

            **USER INPUT VALIDATION**: These tests validate responses provided by the tester,
            not the system under test. Errors will be treated as skips instead of failures.

            For `$#{operation}` responses, this includes the following profiles:

            #{Descriptions.profile_links_list(profiles)}
          DESCRIPTION
        else
          <<~DESCRIPTION
            Check that the client can demonstrate `$#{operation}` requests that contain
            all PAS-defined profiles and their must support elements.

            For `$#{operation}` requests, this includes the following profiles:

            #{Descriptions.profile_links_list(required_profiles, request_profiles: operation == 'submit' ? request_profiles : nil)}
          DESCRIPTION
        end
      end
    end
  end
end
