module DaVinciPASTestKit
  module UserInputResponse
    def self.included(klass)
      klass.extend ClassMethods
    end

    def self.user_inputted_response(configurable, operation, result)
      config_key = operation == 'submit' ? :submit_respond_with : :inquire_respond_with
      input_key = configurable.config.options[config_key]
      return unless input_key.present?

      JSON.parse(result.input_json)&.find { |i| i['name'] == input_key.to_s }&.dig('value')
    rescue JSON::ParserError
      nil
    end

    # Returns the tester-provided response candidates for the must support workflow
    # as a list of parsed JSON hashes. The input value may be a single JSON bundle
    # object or a JSON array of bundle objects. Candidates are kept as raw hashes
    # rather than FHIR model instances so that Inferno selection criteria extensions
    # at the top level of each bundle, which the FHIR Bundle model does not support,
    # are preserved for selection.
    # Returns nil if the input is not present, not parseable, or not object-valued.
    def self.response_bundles(result, operation)
      input_name = operation == 'submit' ? 'ms_submit_responses' : 'ms_inquire_responses'
      input_value = JSON.parse(result.input_json)&.find { |i| i['name'] == input_name }&.dig('value')
      return unless input_value.present?

      bundles = JSON.parse(input_value)
      bundles = [bundles] unless bundles.is_a?(Array)
      bundles if bundles.all?(Hash)
    rescue JSON::ParserError
      nil
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
