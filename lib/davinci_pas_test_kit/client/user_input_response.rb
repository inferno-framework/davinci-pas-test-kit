module DaVinciPASTestKit
  module UserInputResponse
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
    # Returns nil if the input is not present, not parseable, or malformed.
    def self.response_candidates(result, operation)
      input_name = operation == 'submit' ? 'ms_submit_responses' : 'ms_inquire_responses'
      input_value = JSON.parse(result.input_json)&.find { |i| i['name'] == input_name }&.dig('value')
      return unless input_value.present?

      candidates = JSON.parse(input_value)
      candidates = [candidates] unless candidates.is_a?(Array)
      candidates if candidates.all? { |candidate| valid_candidate?(candidate) }
    rescue JSON::ParserError
      nil
    end

    def self.valid_candidate?(candidate)
      return false unless candidate.is_a?(Hash)

      candidate['resourceType'] == 'Bundle' || candidate['bundle'].is_a?(Hash)
    end

    def user_inputted_response?(input_key)
      input_key.present? && send(input_key).present?
    end

    def input_title(input_key)
      config.inputs[input_key]&.title || config.inputs[input_key]&.name
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
