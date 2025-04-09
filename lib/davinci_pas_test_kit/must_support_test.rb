require_relative 'fhir_resource_navigation'

module DaVinciPASTestKit
  module MustSupportTest
    extend Forwardable
    include FHIRResourceNavigation

    def_delegators 'self.class', :metadata

    def all_scratch_resources
      scratch_resources[:all] ||= []
    end

    def reset_variables
      @missing_elements = @missing_slices = @missing_extensions = nil
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

    def validate_must_support(user_input_validation)
      if user_input_validation
        skip_if !all_must_support_errors.empty?, all_must_support_errors.join("\n")
      else
        assert all_must_support_errors.empty?, all_must_support_errors.join("\n")
      end
    end

    def perform_must_support_test(resources)
      assert resources.present?, "No #{resource_type} resources were found"

      missing_must_support_strings = missing_must_support_elements(resources, nil, metadata:)

      return unless missing_must_support_strings.any?

      all_must_support_errors << "Could not find #{missing_must_support_strings.join(', ')} " \
                                 "in the #{resources.length} provided #{resource_type} resource(s)."

      all_must_support_errors.reject! { |err| err.downcase.include?('x12') }
      reset_variables

      # pass if (missing_elements + missing_slices + missing_extensions).empty?

      # assert false, "Could not find #{missing_must_support_strings.join(', ')} in the #{resources.length} " \
      #               "provided #{resource_type} resource(s)"
    end
  end
end
