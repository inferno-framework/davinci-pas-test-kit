require_relative '../../../cross_suite/must_support/must_support_data_gathering'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Aggregates the must support assessment across a list of profiles. Each must support element
    # that was not observed is logged as an info message, and when at least one was not observed the
    # tester is asked to attest that the PAS client does not collect that data. A true attestation
    # passes the test; a false attestation fails it. The attestation option can be disabled
    # using a config entry. When every must support element was observed, the
    # test passes without requiring any further input.
    #
    # The must support assessment - including the shared X12 / DataAbsentReason false-positive
    # handling (remove_must_support_false_positives) is leveraged from the cross_suite must support
    class MustSupportWithAttestationOption < Inferno::Test
      include DaVinciPASTestKit::MustSupportDataGathering
      include URLs

      id :pas_client_v221_must_support_with_attestation_option

      # Recorded in place of a profile's unobserved elements when none of its instances were observed
      # - see gather_unobserved_elements.
      NO_INSTANCES_OBSERVED = :no_instances_observed
      title 'Must support elements are observed across requests'
      description %(
        During this test, Inferno will check that all must support elements defined in the listed
        profiles were observed in the requests made by the PAS client.
      )

      # config.options:
      #   profiles:             Array of { resource_type:, profile_key:, title: } describing the profiles
      #                         to assess.
      #   require_one_of:       Boolean. When true, at least one of the listed resource types must be
      #                         present (a hard requirement) and only the profiles that are actually
      #                         present are assessed - used for the "at least one request profile" case.
      #                         When false, every listed profile is assessed.
      #   ig_version:           version of the id
      #   type:                 'request', or 'response'
      #   operation:            'submit', or 'inquire'
      #   disable_attestation:  boolean indicating whether the attestation option is disabled (default: false)
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

      def attestation_disabled?
        config.options[:disable_attestation]
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

      # Query the repository directly instead of the data gathering default (load_tagged_requests): these
      # requests are owned by the gather test, so associating them here would duplicate that
      # association onto each attestation test's result.
      def must_support_requests
        @must_support_requests ||= Inferno::Repositories::Requests.new.tagged_requests(test_session_id, [tag])
      end

      output :attest_true_url
      output :attest_false_url

      # Hard-fail if no requests were received at all, and (for require_one_of) if none of the
      # target request profiles are present. These are the only failure paths that aren't attestations.
      run do
        assert must_support_requests.present?, "No #{operation} requests received."

        if require_one_of
          assert resources_of_interest.present?,
                 "#{type.titleize} Bundle(s) must include at least one instance of one of these " \
                 "resource types: #{target_resource_types.join(', ')}"
        end

        unobserved_by_profile = gather_unobserved_elements

        unobserved_by_profile.each do |profile_title, elements|
          if elements == NO_INSTANCES_OBSERVED
            add_message('info', "No instances of profile #{profile_title} were observed.")
            next
          end

          elements.each do |element|
            add_message('info', "Unobserved must support element for profile #{profile_title}: #{element}")
          end
        end

        # If nothing was unobserved, the test passes immediately without requiring any attestation.
        # Otherwise, the tester can attest that the client system does not collect, unless disabled
        pass all_observed_message if unobserved_by_profile.empty?
        assert !attestation_disabled?, missing_elements_error_string(unobserved_by_profile)

        # only the tester continues this wait, so use a fresh random identifier - see SessionIdentification
        identifier = SecureRandom.uuid
        output attest_true_url: "#{resume_pass_url}?token=#{identifier}",
               attest_false_url: "#{resume_fail_url}?token=#{identifier}"

        wait(identifier:, message: attestation_message(unobserved_by_profile))
      end

      # @return [Hash{String => Array<String>, Symbol}] unobserved must support elements keyed by profile
      #   title, or NO_INSTANCES_OBSERVED for a profile with no instances at all.
      def gather_unobserved_elements
        profiles.each_with_object({}) do |profile, result|
          profile_title = profile_title(profile)
          resources = grouped_resources[profile[:resource_type]] || []

          if resources.blank?
            # In require_one_of mode the tester only needs to demonstrate one of the alternatives,
            # so a profile with no instances is not flagged. Otherwise, the absence of any instance
            # means the profile's must support elements could not be observed at all - flag the
            # profile itself rather than enumerating every element.
            next if require_one_of

            result[profile_title] = NO_INSTANCES_OBSERVED
            next
          end

          metadata = load_metadata_for_profile_version(profile[:profile_key], ig_version)
          missing = missing_must_support_elements(resources, nil, metadata:)
          missing = remove_must_support_false_positives(missing, resources, profile[:resource_type])

          result[profile_title] = missing if missing.present?
        end
      end

      def profile_title(profile)
        profile[:title] || profile[:resource_type]
      end

      # Titles of the configured profiles whose resource type has instances in the requests.
      def observed_profile_titles
        profiles.select { |profile| grouped_resources[profile[:resource_type]].present? }
          .map { |profile| profile_title(profile) }
      end

      def missing_elements_error_string(unobserved_by_profile)
        unobserved_by_profile.map do |profile_title, elements|
          if elements == NO_INSTANCES_OBSERVED
            "No #{profile_title} resources were observed."
          else
            "Could not find #{elements.join(', ')} in the provided #{profile_title} resource(s)."
          end
        end.join(' ')
      end

      # Names the profiles with instances in the requests so testers can tell which were assessed.
      def all_observed_message
        'All must support elements for the following profiles were observed ' \
          "in the requests made by the PAS client: #{observed_profile_titles.join(', ')}."
      end

      def attestation_message(unobserved_by_profile)
        unobserved_list = unobserved_by_profile.flat_map do |profile_title, elements|
          next ["- #{profile_title}: no instances were observed"] if elements == NO_INSTANCES_OBSERVED

          elements.map { |element| "- #{profile_title}: #{element}" }
        end.join("\n")

        <<~MESSAGE
          The following #{operation} request must support elements were not observed in the
          requests made by the PAS client:

          #{unobserved_list}

          Attest that the PAS client does **not** collect the data for these unobserved
          must support elements (and is not required to under the PAS implementation guide).

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.
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

        intro = description_intro(require_one_of: options[:require_one_of],
                                  attestation_allowed: !options[:disable_attestation])
        "#{intro}\n\n#{sections}"
      end

      # The require_one_of intro reproduces the original PasClientMustSupportRequestProfilesTest
      # description, tweaked only to describe the attestation option when attestation is allowed.
      def self.description_intro(require_one_of:, attestation_allowed: true)
        if require_one_of
          attestation_note = if attestation_allowed
                               ' For must support elements not observed on an included request profile, ' \
                                 'testers can attest that they are not supported by the PAS client.'
                             end
          <<~INTRO.chomp
            The PAS IG includes four profiles for providing the specifics of the service or product requested
            in the prior authorization request. Any one of these profiles can be referenced in
            the must support element `Claim.item.extension:requestedService`:

            * PAS Medication Request
            * PAS Service Request
            * PAS Device Request
            * PAS Nutrition Order

            PAS clients are allowed to support only the request profiles that fit their use cases. However,
            they must support at least one of them (because `Claim.item.extension:requestedService` is a
            must support element) and for any request profiles they support, they must be able to
            populate all of the defined must support elements.

            This test ensures that the submitted request bundles include at least one instance of a
            profile listed above. Then for each profile observed, it checks for the presence of
            each must support element defined in that profile.#{attestation_note}

            The test will look through the instances included in submissions made by the PAS client
            for the following must support elements:
          INTRO
        else
          attestation_note = if attestation_allowed
                               ' For those not observed, testers can attest that they are not supported ' \
                                 'by the PAS client.'
                             end
          <<~INTRO.chomp
            PAS clients are required to be able to populate must support elements representing
            data collected and displayed to users on instances of all profiles included in requests.
            This test checks all identified instances of the profiles listed below within requests sent
            by the PAS client to ensure that the must support elements are observed.#{attestation_note}
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
