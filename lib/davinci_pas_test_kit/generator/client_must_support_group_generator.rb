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
          return '$submit Response Must Support Coverage' if operation == 'submit'

          '$inquire Response Must Support Coverage'
        else
          return '$submit Request Must Support Coverage' if operation == 'submit'

          '$inquire Request Must Support Coverage'
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

      # The collapsed attestation structure / optional response tests are only applied to v2.2.1.
      def optional_must_support_enabled?
        ig_version == 'v2.2.1'
      end

      # The Claim (request) / ClaimResponse (response) profiles remain mandatory standalone tests.
      def mandatory_profile?(profile_metadata)
        %w[Claim ClaimResponse].include?(profile_metadata.resource)
      end

      # Response groups: pairs each per-profile test id with whether it should be marked optional.
      def profile_tests
        profiles.map do |profile_metadata|
          {
            id: test_id_for_profile(profile_metadata),
            optional: optional_must_support_enabled? && !mandatory_profile?(profile_metadata)
          }
        end
      end

      # Collapsed request groups: the mandatory Claim profile(s) kept as standalone tests.
      def claim_profiles
        required_profiles.select { |profile_metadata| profile_metadata.resource == 'Claim' }
      end

      # Collapsed request groups: every other supporting profile, assessed by the attestation test.
      def other_profiles
        required_profiles.reject { |profile_metadata| profile_metadata.resource == 'Claim' }
      end

      def other_profiles_title
        'All must support elements for other profiles referenced by Claim ' \
          "#{operation == 'submit' ? 'submissions' : 'inquiries'} are observed on $#{operation} requests"
      end

      # Formats a profiles list for an attestation test's config, one hash literal per line.
      def attestation_profiles_block(profile_metadatas)
        profile_metadatas.map do |profile_metadata|
          "              { resource_type: '#{profile_metadata.resource}', " \
            "profile_key: '#{profile_identifier(profile_metadata)}', " \
            "title: '#{profile_metadata.profile_name}' }"
        end.join(",\n")
      end

      def profile_test_files
        target_profiles = type == 'response' ? profiles : required_profiles
        target_profiles.map { |profile_metadata| test_file_for_profile(profile_metadata) }
      end

      # Requirement verified by the mandatory per-profile tests in response groups
      # (clients SHALL be capable of receiving must support elements).
      def response_verifies_requirement
        case ig_version
        when 'v2.2.1' then 'hl7.fhir.us.davinci-pas_2.2.1@conf-7'
        when 'v2.0.1' then "hl7.fhir.us.davinci-pas_2.0.1@#{operation == 'submit' ? '39' : '40'}"
        end
      end

      def verifies_requirements
        case "#{operation}_#{type}_#{ig_version}"
        when 'submit_request_v2.2.1', 'inquire_request_v2.2.1'
          ['hl7.fhir.us.davinci-pas_2.2.1@hrex-conf-1']
        end
      end

      # Names of the profiles that must always be demonstrated, e.g. "PAS Claim Inquiry".
      def mandatory_profile_names
        target_profiles = type == 'response' ? profiles : required_profiles
        target_profiles.select { |profile_metadata| mandatory_profile?(profile_metadata) }
          .map(&:profile_name).to_sentence
      end

      # Only v2.2.1 has optional response tests and the request attestation option.
      def optional_profiles_description
        return '' unless optional_must_support_enabled?

        if type == 'response'
          "\nDemonstration of the #{mandatory_profile_names} profile is strictly required\n" \
            'while all others are optional.'
        else
          "\nFor all profiles other than #{mandatory_profile_names}, testers can attest\n" \
            'that the missing elements are not supported by their system to pass the tests.'
        end
      end

      def description
        if type == 'response'
          <<~DESCRIPTION
            Check that `$#{operation}` responses provided to the client contain
            all PAS-defined profiles and their must support elements.#{optional_profiles_description}

            For `$#{operation}` responses, this includes the following profiles:

            #{Descriptions.profile_links_list(profiles, ig_version)}
          DESCRIPTION
        else
          <<~DESCRIPTION
            Check that the client can demonstrate `$#{operation}` requests that contain
            all PAS-defined profiles and their must support elements.#{optional_profiles_description}

            For `$#{operation}` requests, this includes the following profiles:

            #{Descriptions.profile_links_list(required_profiles, ig_version, request_profiles: operation == 'submit' ? request_profiles : nil)}
          DESCRIPTION
        end
      end
    end
  end
end
