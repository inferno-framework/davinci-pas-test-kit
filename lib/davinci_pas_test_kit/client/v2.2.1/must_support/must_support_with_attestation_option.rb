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

      # Hard-fail if no requests were received at all, and (for require_one_of) if none of the
      # target request profiles are present. These are the only failure paths that aren't attestations.
      run do
        assert tagged_resources.present?, "No #{operation} requests received."

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

        sections = profiles.map do |profile|
          metadata = load_profile_metadata(profile[:profile_key], options[:ig_version])
          "### #{profile[:title] || profile[:resource_type]}\n#{metadata.must_support_list_string(indent: 0)}"
        end.join("\n\n")

        "#{description_intro(require_one_of: options[:require_one_of])}\n\n#{sections}"
      end

      # The require_one_of intro reproduces the original PasClientMustSupportRequestProfilesTest
      # description, tweaked only to describe the attestation option. 
      def self.description_intro(require_one_of:)
        if require_one_of
          <<~INTRO.chomp
            The PAS IG includes four profiles for providing the specifics of the service or product requested
            in the prior authorization request. Any one of these profiles can be referenced in
            the must support element `Claim.item.extension:requestedService`:

            * PAS Medication Request
            * PAS Service Request
            * PAS Device Request
            * PAS Nutrition Order

            System are allowed to support only the request profiles that fit their use cases. However,
            they must support at least one of them (because `Claim.item.extension:requestedService` is a
            must support element) and for any request profiles they support, they must be able to
            populate all of the defined must support elements as long as that data is collected within
            and displayed by the system.

            This test ensures that the submitted request bundles include at least one instance of a
            profile listed above. Then for each profile observed, it checks for the presence of
            each must support element defined in that profile. For must support elements not observed
            on an included request profile, testers can attest that they are not supported by the
            client system.

            The test will look through the instances included in submissions made by the client
            for the following must support elements:
          INTRO
        else
          <<~INTRO.chomp
            PAS client systems are required to be able to populate must support elements representing
            data collected and displayed to users on instances of all profiles included in requests.
            This test checks all identified instances of the profiles listed below within requests sent
            by the client to ensure that the must support elements are observed. For those not observed,
            testers can attest that they are not supported by the client system.
          INTRO
        end
      end

      def self.load_profile_metadata(profile_key, version)
        path = File.join(__dir__, '..', '..', '..', 'cross_suite', 'generated', version, profile_key, 'metadata.yml')
        Generator::ProfileMetadata.new(YAML.load_file(path, aliases: true))
      end
    end
  end
end
