require_relative 'fhirpath_utils'

module DaVinciPASTestKit
  # Selection of a response from a tester-provided list of candidate bundles based
  # on criteria represented as extensions at the top level of each candidate.
  # Candidates are handled as parsed JSON hashes rather than FHIR model instances
  # because the FHIR Bundle model does not support top-level extensions and drops
  # them during instantiation.
  # Requires FhirpathUtils and access to `result` (Inferno::Entities::Result).
  module ResponseSelectionUtils
    INCLUSION_CRITERIA_EXTENSION_URL = 'urn:inferno:pas:inclusion-criteria'.freeze
    REQUEST_RANGE_EXTENSION_URL = 'urn:inferno:pas:request-range'.freeze
    INFERNO_CONTROL_EXTENSION_URLS = [
      INCLUSION_CRITERIA_EXTENSION_URL,
      REQUEST_RANGE_EXTENSION_URL
    ].freeze

    # ***********************************************************************
    # Selection of an entity from the candidate list
    # ***********************************************************************

    def include_entity?(entity, request_fhir_obj, operation)
      return false if entity_has_request_range_criteria?(entity) &&
                      !request_meets_request_range_criteria?(entity, operation)
      return false if entity_has_inclusion_criteria?(entity) &&
                      !request_meets_inclusion_criteria?(entity, request_fhir_obj)

      true
    end

    def strip_inferno_extensions(entity)
      extensions = entity_extensions(entity)
      extensions.reject! { |ext| INFERNO_CONTROL_EXTENSION_URLS.include?(ext['url']) }
      entity.delete('extension') if extensions.empty?
      entity
    end

    def entity_extensions(entity)
      extensions = entity.is_a?(Hash) ? entity['extension'] : nil
      extensions.is_a?(Array) ? extensions : []
    end

    # ***********************************************************************
    # FHIRPath-based selection criteria
    # ***********************************************************************

    def entity_has_inclusion_criteria?(entity)
      entity_extensions(entity).any? { |ext| ext['url'] == INCLUSION_CRITERIA_EXTENSION_URL }
    end

    def request_meets_inclusion_criteria?(entity, request_fhir_obj)
      criteria = entity_extensions(entity)
        .find { |ext| ext['url'] == INCLUSION_CRITERIA_EXTENSION_URL }
        &.dig('valueExpression', 'expression')
      return false unless criteria.present?

      fhirpath_result = execute_fhirpath(request_fhir_obj, criteria)
      interpret_fhirpath_result_as_boolean(fhirpath_result)
    end

    # ***********************************************************************
    # Request index-based selection criteria
    # ***********************************************************************

    def entity_has_request_range_criteria?(entity)
      entity_extensions(entity).any? { |ext| ext['url'] == REQUEST_RANGE_EXTENSION_URL }
    end

    def request_meets_request_range_criteria?(entity, operation)
      criteria = entity_extensions(entity).find { |ext| ext['url'] == REQUEST_RANGE_EXTENSION_URL }&.dig('valueString')
      return false unless criteria.present?

      ranges_cover_value?(count_previous_successful_requests(operation) + 1, criteria)
    end

    def count_previous_successful_requests(operation)
      requests_repo = Inferno::Repositories::Requests.new
      previous_requests = requests_repo.requests_for_result(result.id)
      previous_requests.count { |req| req.url.include?(operation) && req.status == 200 }
    end

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
      raise Inferno::Exceptions::TestSuiteImplementationException.new('pas response range criteria', e.message)
    end
  end
end
