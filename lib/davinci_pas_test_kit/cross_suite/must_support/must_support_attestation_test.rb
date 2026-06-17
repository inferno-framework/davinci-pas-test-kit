require_relative 'must_support_data_gathering'
require_relative '../../generator/profile_metadata'
require_relative '../tags'

module DaVinciPASTestKit
  # Abstract must support test that aggregates the must support assessment across a list of
  # profiles. When must support elements are not observed, the tester is given the opportunity
  # to attest that the client system does not collect the related data (and is not required to
  # under the PAS IG). A true attestation passes the test; a false attestation fails it.
  #
  # The PAS IG itself does not require demonstrating every must support element on every profile
  # that can be included in a request - that requirement comes from the referenced HRex IG.
  # This attestation relaxes it for the profiles that are not otherwise mandatory.
  #
  # A concrete subclass must mix in a version-specific URLs module so that resume_pass_url,
  # resume_fail_url, and suite_id are available for the attestation links.
  class MustSupportAttestationTest < Inferno::Test
    include DaVinciPASTestKit::MustSupportDataGathering

    X12_SYSTEM_FRAGMENT = 'x12.org'.freeze
    X12_SLICE = 'Coverage.relationship.coding:X12Code'.freeze
    X12_CHILD = 'relationship.coding:X12Code.code'.freeze

    title 'Generic Must Support Attestation Test'
    description 'Generic Must Support Attestation Test Description'
    id :must_support_attestation_test

    # config.options:
    #   profiles:        Array of { resource_type:, profile_key:, title: } describing the profiles
    #                    to assess.
    #   require_one_of:  Boolean. When true, at least one of the listed resource types must be
    #                    present (a hard requirement) and only the profiles that are actually
    #                    present are assessed - used for the "at least one request profile" case
    #                    where the tester only needs to demonstrate one of several alternatives.
    #                    When false, every listed profile is assessed and any that are entirely
    #                    absent contribute all of their must support elements as unobserved.
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

    run do
      if require_one_of
        assert resources_of_interest.present?,
               "#{type.titleize} Bundle(s) must include at least one instance of one of these " \
               "resource types: #{target_resource_types.join(', ')}"
      end

      unobserved_by_profile = gather_unobserved_elements

      unobserved_by_profile.each do |profile_title, missing|
        add_message('info', %(
          Must support elements not observed for **#{profile_title}** (attested as not collected
          by the client system):

          #{missing.map { |element| "* #{element}" }.join("\n")}
        ))
      end

      pass 'All must support elements were observed across the provided resources.' if unobserved_by_profile.empty?

      identifier = test_session_id
      output attest_true_url: "#{resume_pass_url}?token=#{identifier}",
             attest_false_url: "#{resume_fail_url}?token=#{identifier}"

      wait(
        identifier:,
        message: attestation_message(unobserved_by_profile)
      )
    end

    # @return unobserved must support elements keyed by profile title
    def gather_unobserved_elements
      profiles.each_with_object({}) do |profile, result|
        resources = grouped_resources[profile[:resource_type]] || []

        # In require_one_of mode only assess the alternatives that are actually present, since the
        # tester is only expected to demonstrate at least one of them.
        next if require_one_of && resources.blank?

        metadata = load_metadata_for_profile_version(profile[:profile_key], ig_version)
        missing = missing_must_support_elements(resources, nil, metadata:)
        missing = remove_x12_coverage_false_positives(missing, resources) if profile[:resource_type] == 'Coverage'

        result[profile[:title] || profile[:resource_type]] = missing if missing.present?
      end
    end

    # Coverage.relationship.coding:X12Code has an empty required binding discriminator values list,
    # so Inferno cannot reliably detect it automatically. Approximate by checking for an x12.org
    # system on Coverage.relationship.coding.
    def remove_x12_coverage_false_positives(missing, resources)
      return missing unless missing.include?(X12_SLICE)

      has_x12_coding = resources.any? do |resource|
        resource.relationship&.coding&.any? { |coding| coding.system&.include?(X12_SYSTEM_FRAGMENT) }
      end
      return missing unless has_x12_coding

      missing - [X12_SLICE, X12_CHILD]
    end

    def attestation_message(unobserved_by_profile)
      element_list = unobserved_by_profile.map do |profile_title, missing|
        "**#{profile_title}**\n#{missing.map { |element| "  * #{element}" }.join("\n")}"
      end.join("\n\n")

      <<~MESSAGE
        The following must support elements were **not observed** in the #{operation} requests made
        by the client:

        #{element_list}

        Attest that the client system does **not** collect the data for the unobserved elements
        listed above (and is not required to under the PAS IG).

        [Click here](#{attest_true_url}) if the above statement is **true**. The test will **pass**.

        [Click here](#{attest_false_url}) if the above statement is **false**. The test will **fail**.
      MESSAGE
    end
  end
end
