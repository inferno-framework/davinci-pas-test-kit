require_relative 'response_template'

module DaVinciPASTestKit
  # Utilities for evaluating FHIRPath expressions against FHIR resources using
  # the FHIRPath evaluation service and for instantiating response templates
  # with values pulled from a request.
  module FhirpathUtils
    # Raised when the FHIRPath service cannot be reached or does not return a usable
    # result. Messages name the query and end with the service's response or the
    # connection error so that they can be shown to the tester as-is.
    class FhirpathServiceError < StandardError; end

    def fhirpath_evaluator
      @fhirpath_evaluator ||= Inferno::DSL::FhirpathEvaluation::Evaluator.new
    end

    # The query is URL encoded because the evaluator adds it to the service URL as given, where a `+`
    # would be read as a space and a `&` would end the query.
    def execute_fhirpath(body, query)
      fhirpath_result = fhirpath_evaluator.call_fhirpath_service(body, ERB::Util.url_encode(query))
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

    # Instantiates a parsed JSON response template against the request - see ResponseTemplate.
    def instantiate_template(template, request)
      ResponseTemplate.new(request, self).instantiate(template)
    end

    # @return [Array] the element of each result of the expression evaluated against the resource.
    def evaluate_fhirpath_elements(resource, expression)
      fhirpath_result = execute_fhirpath(resource, expression)
      results = JSON.parse(fhirpath_result.body)
      raise JSON::ParserError unless results.is_a?(Array) && results.all?(Hash)

      results.map { |result| result['element'] }
    rescue JSON::ParserError
      raise FhirpathServiceError,
            "The FHIRPath service returned an unparseable response for query '#{expression}': " \
            "#{fhirpath_result.body}"
    end
  end
end
