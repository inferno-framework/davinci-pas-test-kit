require_relative 'must_support_data_gathering'
require_relative '../../generator/profile_metadata'
require_relative '../tags'

module DaVinciPASTestKit
  class MustSupportRequestTypeTest < Inferno::Test
    include DaVinciPASTestKit::MustSupportDataGathering

    title 'Generic Must Support Request Type Test'
    description 'Generic Must Support Request Type Test Description'
    id :must_support_request_type_test

    def profile_keys
      config.options[:profile_keys]
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

    def metadata_array
      @metadata_array ||= profile_keys.each_with_object({}) do |profile_key, metadata_array|
        metadata_array[profile_key.camelize] =
          Generator::ProfileMetadata.new(
            YAML.load_file(File.join(__dir__, '..', 'generated', ig_version, profile_key, 'metadata.yml'),
                           aliases: true)
          )
      end
    end

    def target_resource_types
      @target_resource_types ||= profile_keys.map(&:camelize)
    end

    def type_of_interest?(type)
      target_resource_types.include?(type)
    end

    def grouped_resources
      resources_of_interest.group_by(&:resourceType)
    end

    run do
      assert resources_of_interest.present?,
             "#{type.titleize} Bundle(s) must include at least one instance of one of these resource types: " \
             "#{target_resource_types.join(', ')}"

      errors = []
      grouped_resources.each do |type, resources|
        missing_must_support_strings = missing_must_support_elements_with_optional_slices(resources, metadata_array[type])
        errors << error_message(missing_must_support_strings, resources, type) if missing_must_support_strings.present?
      end

      if errors.present?
        message = errors.join("\n")
        if user_input_validation
          skip_if true, message
        else
          assert false, message
        end
      end
    end
  end
end
