require_relative 'must_support_target_profiles'

module DaVinciPASTestKit
  class Generator
    class MustSupportTestGenerator
      class << self
        def generate(ig_metadata, base_server_output_dir, base_client_output_dir)
          submit_request_profiles =
            ig_metadata.profiles.select { |profile| MustSupportTargetProfiles.submit_request_profile?(profile) }
              .reject { |profile| MustSupportTargetProfiles.request_profile?(profile) }
          submit_response_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.submit_response_profile?(profile)
          end
          inquiry_request_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.inquire_request_profile?(profile)
          end
          inquiry_response_profiles = ig_metadata.profiles.select do |profile|
            MustSupportTargetProfiles.inquire_response_profile?(profile)
          end

          submit_request_profiles.each do |profile|
            new(ig_metadata, profile, base_server_output_dir, 'request', 'submit').generate
            if generate_client_request_test?(ig_metadata, profile)
              new(ig_metadata, profile, base_client_output_dir, 'request', 'submit', 'client').generate
            end
          end
          submit_response_profiles.each do |profile|
            new(ig_metadata, profile, base_server_output_dir, 'response', 'submit').generate
            new(ig_metadata, profile, base_client_output_dir, 'response', 'submit', 'client').generate
          end

          inquiry_request_profiles.each do |profile|
            new(ig_metadata, profile, base_server_output_dir, 'request', 'inquire').generate
            if generate_client_request_test?(ig_metadata, profile)
              new(ig_metadata, profile, base_client_output_dir, 'request', 'inquire', 'client').generate
            end
          end
          inquiry_response_profiles.each do |profile|
            new(ig_metadata, profile, base_server_output_dir, 'response', 'inquire').generate
            new(ig_metadata, profile, base_client_output_dir, 'response', 'inquire', 'client').generate
          end
        end

        # For v2.2.1 the client request must support tests are collapsed into the attestation tests
        # (see ClientMustSupportGroupGenerator), so only the mandatory Claim profile keeps a
        # standalone per-profile client request test. Other profiles are covered by the attestation
        # tests and their per-profile client request tests are not generated. Server tests and
        # earlier IG versions are unaffected.
        def generate_client_request_test?(ig_metadata, profile)
          return true unless ig_metadata.ig_version == 'v2.2.1'

          profile.resource == 'Claim'
        end
      end

      attr_accessor :ig_metadata, :profile_metadata, :base_output_dir, :type, :operation, :system

      def initialize(ig_metadata, profile_metadata, base_output_dir, type, operation, system = 'server')
        self.ig_metadata = ig_metadata
        self.profile_metadata = profile_metadata
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
        self.class.read_interaction(profile_metadata)
      end

      def profile_identifier
        ig_metadata.snake_case_for_profile(profile_metadata)
      end

      def request_type
        "#{operation}_#{type}"
      end

      def test_id
        "pas_#{system}_#{profile_metadata.reformatted_version}_#{request_type}_must_support_#{profile_identifier}"
      end

      def class_name
        "#{system.capitalize}#{request_type.camelize}MustSupport" \
          "#{ig_metadata.upper_camel_case_for_profile(profile_metadata)}Test"
      end

      def module_name
        "DaVinciPAS#{profile_metadata.reformatted_version.upcase}"
      end

      def resource_type
        profile_metadata.resource
      end

      def profile_name
        profile_metadata.profile_name
      end

      def must_support_list_string
        profile_metadata.must_support_list_string(indent: 8)
      end

      def verifies_requirements
        case "#{system}_#{operation}_#{type}_#{ig_metadata.ig_version}"
        when 'server_submit_response_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@37', 'hl7.fhir.us.davinci-pas_2.0.1@110']
        when 'server_inquire_response_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@38']
        end
      end

      def generate
        FileUtils.mkdir_p(output_file_directory)
        File.write(output_file_name, output)

        profile_metadata.add_test(
          id: test_id,
          file_name: base_output_file_name
        )
      end
    end
  end
end
