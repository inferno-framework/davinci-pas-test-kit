module DaVinciPASTestKit
  # Utilities for evaluating FHIRPath expressions against FHIR resources using
  # the FHIRPath evaluation service and for replacing {{fhirpath}} tokens in
  # serialized resources with values pulled from a request.
  module FhirpathUtils
    # Raised when the FHIRPath service cannot be reached or does not return a usable
    # result. Messages name the query and end with the service's response or the
    # connection error so that they can be shown to the tester as-is.
    class FhirpathServiceError < StandardError; end

    def fhirpath_evaluator
      @fhirpath_evaluator ||= Inferno::DSL::FhirpathEvaluation::Evaluator.new
    end

    def execute_fhirpath(body, query)
      fhirpath_result = fhirpath_evaluator.call_fhirpath_service(body, query)
      return fhirpath_result if fhirpath_result.status.to_s.start_with?('2')

      raise FhirpathServiceError,
            "The FHIRPath service returned HTTP #{fhirpath_result.status} for query '#{query}': " \
            "#{fhirpath_result.body}"
    rescue Faraday::Error => e
      raise FhirpathServiceError, "The FHIRPath service request for query '#{query}' failed: #{e.message}"
    end

    def interpret_fhirpath_result_as_boolean(fhirpath_result)
      results = JSON.parse(fhirpath_result.body)
      if results.empty? || results.size > 1
        false
      elsif results.first['type'] == 'boolean'
        results.first['element']
      else
        true
      end
    rescue JSON::ParserError
      false
    end

    def replace_tokens_in_string(string, request)
      return string unless string.include?('{{')

      tokens_to_replace = string.scan(/\{\{([^}]+)\}\}/).flatten
      replacements = tokens_to_replace.each_with_object({}) do |expression, dictionary|
        next if dictionary.key?("{{#{expression}}}")

        dictionary["{{#{expression}}}"] = calculate_expression_string_value(request, expression)
      end

      string.gsub(/\{\{.*?\}\}/, replacements)
    end

    def calculate_expression_string_value(request, expression)
      fhirpath_result = execute_fhirpath(request, expression)
      JSON.parse(fhirpath_result.body)
        .map { |result| result['element'] }
        .map { |element| element.is_a?(Array) || element.is_a?(Hash) ? nil : element }
        .compact
        .join(',')
    rescue JSON::ParserError
      raise FhirpathServiceError,
            "The FHIRPath service returned an unparseable response for query '#{expression}': " \
            "#{fhirpath_result.body}"
    end
  end
end
