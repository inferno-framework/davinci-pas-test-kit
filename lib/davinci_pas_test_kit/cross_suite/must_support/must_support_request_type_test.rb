module DaVinciPASTestKit
  module MustSupportRequestTypeTest
    def resource_metadata(resource_type)
      metadata_array[resource_type]
    end

    def resource_type_must_support_list(resource_type)
      metadata_array[resource_type][:must_supports][:extensions].map { |ext| ext[:id] } +
        metadata_array[resource_type][:must_supports][:slices].map { |slice| slice[:slice_id] } +
        metadata_array[resource_type][:must_supports][:elements].map { |elt| elt[:path] }
    end

    def metadata_array
      @metadata_array = target_resource_types.each_with_object({}) do |resource_type, metadata_array|
        metadata_file_name = "#{resource_type.downcase.gsub(' ', '_')}_metadata.yml"
        metadata_array[resource_type] =
          Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, version, metadata_file_name), aliases: true))
      end
    end

    def target_resource_types
      @target_resource_types =
        Dir.glob("#{version}/*_metadata.yml").map { |filename| filename.chomp('_metadata.yml').camelize }
    end

    def target_profiles
      @target_profiles = target_resource_types.map { |resource_type| "PAS #{resource_type.titleize}" }
    end

    def resource_type_description_details
      target_resource_types.map do |resource_type|
        "### PAS #{resource_type.titleize}\n* " + resource_type_must_support_list.join("\n* ")
      end.join("\n\n")
    end

    def grouped_resources(resources_of_interest)
      resources_of_interest.group_by(&:resourceType)
    end

    def tagged_resources(tag)
      resources = []
      load_tagged_requests(tag)
      return resources if requests.empty?

      requests.each do |req|
        begin
          bundle = FHIR.from_contents(req.request_body)
        rescue StandardError
          next
        end

        next unless bundle.is_a?(FHIR::Bundle)

        resources << bundle
        entry_resources = bundle.entry.map(&:resource)
        resources.concat(entry_resources)
      end

      resources
    end

    def all_must_support_errors
      @all_must_support_errors ||= []
    end

    def validate_must_support(user_input_validation: false)
      if user_input_validation
        skip_if !all_must_support_errors.empty?, all_must_support_errors.join("\n")
      else
        assert all_must_support_errors.empty?, all_must_support_errors.join("\n")
      end
    end

    def check_must_supports_for_resource_type(resources, resource_type)
      assert resources.present?, "No #{resource_type} resources were found"

      metadata = resource_metadata(resource_type)

      missing_must_support_strings = missing_must_support_elements(resources, nil, metadata:)

      return unless missing_must_support_strings.any?

      all_must_support_errors << "Could not find #{missing_must_support_strings.join(', ')} " \
                                 "in the #{resources.length} provided #{resource_type} resource(s)."

      all_must_support_errors.reject! { |err| err.downcase.include?('x12') }
    end

    def run_must_support_test(resources_of_interest, user_input_validation: false)
      target_types = target_resource_types
      msg = "Request Bundle must include an instance of at least one of these types: #{target_types.join(', ')}"
      assert resources_of_interest.present?, msg

      grouped_resources(resources_of_interest).each do |type, resources|
        check_must_supports_for_resource_type(resources, type)
      end
      validate_must_support(user_input_validation:)
    end
  end
end
