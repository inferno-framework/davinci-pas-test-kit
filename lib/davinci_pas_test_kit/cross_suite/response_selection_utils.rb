require_relative 'fhirpath_utils'

module DaVinciPASTestKit
  # Selection of a response from a tester-provided list of candidates. Each candidate
  # is either a bare FHIR Bundle or a plain JSON wrapper object pairing the response
  # Bundle ("bundle") with the selection criteria ("criteria") that the incoming
  # request must meet for that Bundle to be returned. The wrapper is plain JSON
  # rather than FHIR because Bundle resources cannot carry top-level extensions.
  # Candidates are handled as parsed JSON hashes; the inner Bundle is a clean FHIR
  # resource and needs no modification before use.
  # Requires FhirpathUtils and access to `result` (Inferno::Entities::Result).
  module ResponseSelectionUtils
    CRITERIA_KEY = 'criteria'.freeze
    BUNDLE_KEY = 'bundle'.freeze
    REQUEST_RANGE_KEY = 'requestRange'.freeze
    FHIRPATH_KEY = 'fhirpath'.freeze

    # ***********************************************************************
    # Candidate handling
    # ***********************************************************************

    def bare_bundle?(entity)
      entity.is_a?(Hash) && entity['resourceType'] == 'Bundle'
    end

    def entity_bundle(entity)
      bare_bundle?(entity) ? entity : entity[BUNDLE_KEY]
    end

    def entity_criteria(entity)
      criteria = bare_bundle?(entity) ? nil : entity[CRITERIA_KEY]
      criteria.is_a?(Hash) ? criteria : {}
    end

    def include_entity?(entity, request_fhir_obj, request_number)
      criteria = entity_criteria(entity)
      return false if criteria[REQUEST_RANGE_KEY].present? &&
                      !ranges_cover_value?(request_number, criteria[REQUEST_RANGE_KEY].to_s)
      return false if criteria[FHIRPATH_KEY].present? &&
                      !request_meets_inclusion_criteria?(criteria[FHIRPATH_KEY], request_fhir_obj)

      true
    end

    # ***********************************************************************
    # FHIRPath-based selection criteria
    # ***********************************************************************

    def request_meets_inclusion_criteria?(expression, request_fhir_obj)
      fhirpath_result = execute_fhirpath(request_fhir_obj, expression)
      interpret_fhirpath_result_as_boolean(fhirpath_result)
    end

    # ***********************************************************************
    # Request index-based selection criteria
    # ***********************************************************************

    def count_previous_successful_requests(operation)
      requests_repo = Inferno::Repositories::Requests.new
      previous_requests = requests_repo.requests_for_result(result.id)
      previous_requests.count { |req| req.url.include?(operation) && req.status == 200 }
    end

    # An invalid range comes from tester input, so it is logged and treated as unmet
    # rather than raised, leaving the candidate unselected.
    def ranges_cover_value?(value, ranges_string)
      unless /\A(\d+(-\d+)?,)*\d+(-\d+)?\z/.match?(ranges_string)
        raise ArgumentError,
              "Invalid range string: #{ranges_string.inspect}"
      end

      ranges_string.split(',').any? do |part|
        if part.include?('-')
          low, high = part.split('-').map(&:to_i)
          raise ArgumentError, "Inverted range in: #{part.inspect}" if low > high

          (low..high).cover?(value)
        else
          part.to_i == value
        end
      end
    rescue ArgumentError => e
      Inferno::Application['logger'].warn("Ignoring unmatchable requestRange criteria: #{e.message}")
      false
    end
  end
end
