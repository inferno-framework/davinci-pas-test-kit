module DaVinciPASTestKit
  module UserInputResponse
    # Raised when a tester-provided response input is present but cannot be used. The
    # message explains why in terms the tester can act on.
    class InvalidInputError < StandardError; end

    def self.included(klass)
      klass.extend ClassMethods
    end

    # Reads an arbitrary input value by name from result.input_json.
    def self.read_input(result, input_name)
      JSON.parse(result.input_json)&.find { |i| i['name'] == input_name.to_s }&.dig('value')
    rescue JSON::ParserError
      nil
    end

    def self.user_inputted_response(configurable, operation, result)
      config_key = operation == 'submit' ? :submit_respond_with : :inquire_respond_with
      input_key = configurable.config.options[config_key]
      return unless input_key.present?

      read_input(result, input_key)
    end

    # Returns the tester-provided response candidates for the must support workflow
    # as a list of parsed JSON hashes. The input value may be a single entry or a
    # JSON array of entries, where each entry is either a bare FHIR Bundle or a
    # wrapper object holding the response Bundle under "bundle" alongside optional
    # selection "criteria".
    # Returns nil if the input has no value and raises InvalidInputError if the value
    # is present but unusable. The configurable (the waiting test) supplies the input
    # title so that the error names the input as the tester sees it.
    def self.response_candidates(configurable, operation, result)
      input_name = operation == 'submit' ? 'ms_submit_responses' : 'ms_inquire_responses'
      input_value = read_input(result, input_name)
      return unless input_value.present?

      candidates = JSON.parse(input_value)
      candidates = [candidates] unless candidates.is_a?(Array)
      invalid_index = candidates.index { |candidate| !valid_candidate?(candidate) }
      if invalid_index.present?
        raise InvalidInputError,
              "Entry #{invalid_index + 1} of the '#{input_title(configurable, input_name)}' input is neither " \
              'a FHIR Bundle nor a wrapper object with a FHIR Bundle in the "bundle" key.'
      end

      candidates
    rescue JSON::ParserError
      raise InvalidInputError, "The '#{input_title(configurable, input_name)}' input is not valid JSON."
    end

    # Title of an input as shown to the tester in the Inferno UI, falling back to its name
    def self.input_title(configurable, input_key)
      input = configurable.config.inputs[input_key.to_sym]
      (input&.title || input&.name || input_key).to_s
    end

    def self.valid_candidate?(candidate)
      return false unless candidate.is_a?(Hash)

      candidate['resourceType'] == 'Bundle' || candidate['bundle'].is_a?(Hash)
    end

    def user_inputted_response?(input_key)
      input_key.present? && send(input_key).present?
    end

    def input_title(input_key)
      UserInputResponse.input_title(self, input_key)
    end

    module ClassMethods
      def submit_respond_with(key)
        config options: { submit_respond_with: key }
      end

      def inquire_respond_with(key)
        config options: { inquire_respond_with: key }
      end
    end
  end
end
