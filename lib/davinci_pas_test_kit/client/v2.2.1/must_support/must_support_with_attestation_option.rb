require_relative '../../../cross_suite/must_support/must_support_data_gathering'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Aggregates the must support assessment across a list of profiles. Each must support element
    # that was not observed is logged as an info message, and when at least one was not observed the
    # tester is given the opportunity to attest that the client system does not collect that data
    # (and is not required to under the PAS implementation guide). A true attestation passes the
    # test; a false attestation fails it. When every must support element was observed, the test
    # passes without requiring any further input.
    #
    # The must support assessment - including the shared X12 / DataAbsentReason false-positive
    # handling (remove_must_support_false_positives) is leveraged from the cross_suite must support
    class MustSupportWithAttestationOption < Inferno::Test
      include DaVinciPASTestKit::MustSupportDataGathering
      include URLs

      id :pas_client_v221_must_support_with_attestation_option
      title 'Must support elements are observed across requests'
      description %(
        This test reviews the must support elements observed across the listed profiles in the
        requests made by the client. If any were not observed, the tester has the opportunity to
        attest that the client system does not collect that data (and is not required to under the
        PAS implementation guide).
      )

      # config.options:
      #   profiles:        Array of { resource_type:, profile_key:, title: } describing the profiles
      #                    to assess.
      #   require_one_of:  Boolean. When true, at least one of the listed resource types must be
      #                    present (a hard requirement) and only the profiles that are actually
      #                    present are assessed - used for the "at least one request profile" case.
      #                    When false, every listed profile is assessed.
      #   ig_version:, type: ('request'), operation: ('submit' / 'inquire')
      def profiles
        config.options[:profiles]
      end

      def require_one_of
        config.options[:require_one_of]
      end

      def ig_version
        config.options[:ig_version]
      end

      def type
        config.options[:type]
      end

      def operation
        config.options[:operation]
      end

      def target_resource_types
        @target_resource_types ||= profiles.map { |profile| profile[:resource_type] }.uniq
      end

      def type_of_interest?(resource_type)
        target_resource_types.include?(resource_type)
      end

      def grouped_resources
        @grouped_resources ||= (resources_of_interest || []).group_by(&:resourceType)
      end

      output :attest_true_url
      output :attest_false_url

      # Hard-fail unless at least one of the target resource types is present.
      # This is the only true failure path that isn't an attestation.
      run do
        if require_one_of
          assert resources_of_interest.present?,
                 "#{type.titleize} Bundle(s) must include at least one instance of one of these " \
                 "resource types: #{target_resource_types.join(', ')}"
        end

        unobserved_by_profile = gather_unobserved_elements

        unobserved_by_profile.each do |profile_title, elements|
          elements.each do |element|
            add_message('info', "Unobserved must support element for profile #{profile_title}: #{element}")
          end
        end

        # If nothing was unobserved, the test passes immediately without requiring any attestation.
        # Otherwise, the tester is given the opportunity to attest that the client system does not collect
        pass 'All must support elements were observed in the requests made by the client.' if
          unobserved_by_profile.empty?

        identifier = test_session_id
        output attest_true_url: "#{resume_pass_url}?token=#{identifier}",
               attest_false_url: "#{resume_fail_url}?token=#{identifier}"

        wait(identifier:, message: attestation_message(unobserved_by_profile))
      end

      # @return unobserved must support elements keyed by profile title
      def gather_unobserved_elements
        profiles.each_with_object({}) do |profile, result|
          profile_title = profile[:title] || profile[:resource_type]
          resources = grouped_resources[profile[:resource_type]] || []

          if resources.blank?
            # In require_one_of mode the tester only needs to demonstrate one of the alternatives,
            # so a profile with no instances is not flagged. Otherwise, the absence of any instance
            # means the profile's must support elements could not be observed at all - flag the
            # resource type itself rather than enumerating every element.
            next if require_one_of

            result[profile_title] = ["(no #{profile[:resource_type]} instances were observed)"]
            next
          end

          metadata = load_metadata_for_profile_version(profile[:profile_key], ig_version)
          missing = missing_must_support_elements(resources, nil, metadata:)
          missing = remove_must_support_false_positives(missing, resources, profile[:resource_type])

          result[profile_title] = missing if missing.present?
        end
      end

      def attestation_message(unobserved_by_profile)
        unobserved_list = unobserved_by_profile.flat_map do |profile_title, elements|
          elements.map { |element| "- #{profile_title}: #{element}" }
        end.join("\n")

        <<~MESSAGE
          The following #{operation} request must support elements were not observed in the
          requests made by the client:

          #{unobserved_list}

          Attest that the client system does **not** collect the data for these unobserved
          must support elements (and is not required to under the PAS implementation guide).

          [Click here](#{attest_true_url}) if the above statement is **true**. The test will **pass**.

          [Click here](#{attest_false_url}) if the above statement is **false**. The test will **fail**.
        MESSAGE
      end

      # Builds the test's description from the configured profiles' metadata at load time, so the
      # generated group files stay lean and the listed must support elements stay in sync with the
      # IG metadata. Called from the generated groups: `description build_description(config.options)`.
      def self.build_description(options)
        profiles = options[:profiles] || []
        operation = options[:operation]

        sections = profiles.map do |profile|
          metadata = load_profile_metadata(profile[:profile_key], options[:ig_version])
          "### #{profile[:title] || profile[:resource_type]}\n#{metadata.must_support_list_string(indent: 0)}"
        end.join("\n\n")

        "#{description_intro(operation, require_one_of: options[:require_one_of])}\n\n#{sections}"
      end

      def self.description_intro(operation, require_one_of:)
        if require_one_of
          'The PAS IG defines several request profiles for the specifics of the requested service or ' \
            'product. A client must support at least one of them. For each request profile present in the ' \
            "client's $#{operation} requests, this test checks all of its must support elements; any " \
            'element that was not observed may be attested as not collected by the client (and is not ' \
            'required under the PAS implementation guide).'
        else
          "This test reviews the listed PAS profiles in the client's $#{operation} requests and checks " \
            'all of their must support elements. Any element that was not observed may be attested as ' \
            'not collected by the client (and is not required under the PAS implementation guide).'
        end
      end

      def self.load_profile_metadata(profile_key, version)
        path = File.join(__dir__, '..', '..', '..', 'cross_suite', 'generated', version, profile_key, 'metadata.yml')
        Generator::ProfileMetadata.new(YAML.load_file(path, aliases: true))
      end
    end
  end
end
