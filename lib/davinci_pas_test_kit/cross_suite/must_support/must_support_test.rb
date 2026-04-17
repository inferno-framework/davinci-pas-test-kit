require_relative 'must_support_data_gathering'
require_relative '../../generator/profile_metadata'
require_relative '../tags'

module DaVinciPASTestKit
  class MustSupportTest < Inferno::Test
    include DaVinciPASTestKit::MustSupportDataGathering

    X12_SYSTEM_FRAGMENT = 'x12.org'.freeze
    X12_SLICE = 'Coverage.relationship.coding:X12Code'.freeze
    X12_CHILD = 'relationship.coding:X12Code.code'.freeze

    title 'Generic Must Support Test'
    description 'Generic Must Support Test Description'

    id :must_support_test

    def resource_type
      config.options[:resource_type]
    end

    def profile_key
      config.options[:profile_key]
    end

    def user_input_validation
      config.options[:user_input_validation]
    end

    def ig_version
      config.options[:ig_version]
    end

    def type
      config.options[:type] # request or response
    end

    def operation
      config.options[:operation]
    end

    def type_of_interest?(type)
      type == resource_type
    end

    def metadata
      @metadata ||= load_metadata_for_profile_version(profile_key, ig_version)
    end

    run do
      if user_input_validation
        skip_if resources_of_interest.blank?, "No #{resource_type} resources were found"
      else
        assert resources_of_interest.present?, "No #{resource_type} resources were found"
      end

      missing_must_support_strings = missing_must_support_elements(resources_of_interest, nil, metadata:)

      # Special case: Coverage.relationship.coding:X12Code slice has an empty required binding
      # discriminator values list, so Inferno cannot reliably detect it automatically.
      # Ideally this should be determined from ClaimResponse context, but since this test
      # operates on Coverage resources, we approximate by checking for x12.org in
      # Coverage.relationship.coding.system.
      if resource_type == 'Coverage' && missing_must_support_strings.include?(X12_SLICE)
        has_x12_coding = resources_of_interest.any? do |resource|
          resource.relationship&.coding&.any? do |coding|
            coding.system&.include?(X12_SYSTEM_FRAGMENT)
          end
        end

        if has_x12_coding
          missing_must_support_strings.delete(X12_SLICE)
          missing_must_support_strings.delete(X12_CHILD)
        end
      end

      if missing_must_support_strings.present?
        message = error_message(missing_must_support_strings, resources_of_interest, resource_type)
        if user_input_validation
          skip_if true, message
        else
          assert false, message
        end
      end
    end
  end
end
