require_relative 'custom_extension_removal'

module DaVinciPASTestKit
  # Instantiates a tester-provided response template (parsed JSON) using values from a request:
  # - A string that is exactly one `{{fhirpath}}` token is replaced by the typed results of the expression.
  #   In an array, every result is inserted in its place. In an object, no result removes the element,
  #   one result becomes its value, and several become an array. Copied data types lose extensions not
  #   published by HL7, while resources and Bundle entries are copied as they are.
  # - Tokens within a longer string are replaced by their primitive results joined with commas.
  # - A `{ "$forEach": "<fhirpath>", "template": <value> }` object becomes one copy of the template for
  #   each result of the expression, in which `%current` in token expressions refers to that result.
  #   In an object, the copies always form an array.
  class ResponseTemplate
    # Raised when the template's structure is invalid. Messages can be shown to the tester as-is.
    class TemplateError < StandardError; end

    TOKEN_PATTERN = /\{\{([^}]+)\}\}/
    WHOLE_TOKEN_PATTERN = /\A\{\{([^}]+)\}\}\z/
    FOR_EACH_KEY = '$forEach'.freeze
    TEMPLATE_KEY = 'template'.freeze
    CURRENT_VARIABLE_PATTERN = /%current\b/

    # Whether the JSON contains anything to instantiate
    def self.template?(json)
      json.include?('{{') || json.include?("\"#{FOR_EACH_KEY}\"")
    end

    # @param request [FHIR::Model] the resource expressions are evaluated against.
    # @param evaluator [#evaluate_fhirpath_elements] see FhirpathUtils.
    def initialize(request, evaluator)
      @request = request
      @evaluator = evaluator
      @results = {}
    end

    # @param template [Hash] parsed JSON.
    # @return [Hash] the instantiated JSON.
    def instantiate(template)
      return instantiate_object(template) if template.is_a?(Hash) && !for_each?(template)

      raise TemplateError, 'A response template must be a JSON object.'
    end

    private

    # @return [Array] the values that the template value becomes, in order.
    def expand(value)
      case value
      when Hash
        for_each?(value) ? expand_for_each(value) : [instantiate_object(value)]
      when Array
        [value.flat_map { |item| expand(item) }]
      when String
        expand_string(value)
      else
        [value]
      end
    end

    def instantiate_object(object)
      object.each_with_object({}) do |(key, child), result|
        values = expand(child)
        values = [values] if values.size > 1 || (for_each?(child) && values.present?)
        result[key] = values.first unless values.empty? || values.first == []
      end
    end

    def expand_string(string)
      whole_token = string.match(WHOLE_TOKEN_PATTERN)
      return evaluate(whole_token[1]).map { |element| copy_element(element) } if whole_token

      [string.gsub(TOKEN_PATTERN) { evaluate(::Regexp.last_match(1)).grep_v(Enumerable).join(',') }]
    end

    def for_each?(value)
      value.is_a?(Hash) && value.key?(FOR_EACH_KEY)
    end

    def expand_for_each(directive)
      expression = directive[FOR_EACH_KEY]
      unless directive.keys.sort == [FOR_EACH_KEY, TEMPLATE_KEY] && expression.is_a?(String) && expression.present?
        raise TemplateError,
              "A \"#{FOR_EACH_KEY}\" object must contain only a \"#{FOR_EACH_KEY}\" FHIRPath expression and a " \
              "\"#{TEMPLATE_KEY}\", but found keys #{directive.keys.map { |k| "\"#{k}\"" }.join(', ')}."
      end

      Array.new(evaluate(expression).size) do |index|
        expand(with_current(directive[TEMPLATE_KEY], "(#{expression})[#{index}]"))
      end.flatten(1)
    end

    # Replaces %current in the template's token expressions, except within the templates of nested
    # $forEach objects, where %current refers to the nested item.
    def with_current(value, replacement)
      case value
      when Hash
        if for_each?(value)
          value.merge(FOR_EACH_KEY => value[FOR_EACH_KEY].to_s.gsub(CURRENT_VARIABLE_PATTERN, replacement))
        else
          value.transform_values { |child| with_current(child, replacement) }
        end
      when Array
        value.map { |child| with_current(child, replacement) }
      when String
        value.gsub(TOKEN_PATTERN) { "{{#{::Regexp.last_match(1).gsub(CURRENT_VARIABLE_PATTERN, replacement)}}}" }
      else
        value
      end
    end

    def evaluate(expression)
      if expression.match?(CURRENT_VARIABLE_PATTERN)
        raise TemplateError,
              "The expression '#{expression}' uses %current outside of a \"#{FOR_EACH_KEY}\" template."
      end

      @results[expression] ||= @evaluator.evaluate_fhirpath_elements(@request, expression).compact
    end

    def copy_element(element)
      return element unless element.is_a?(Hash)
      return element if element.key?('resourceType') || element.key?('resource')

      CustomExtensionRemoval.without_custom_extensions(element)
    end
  end
end
