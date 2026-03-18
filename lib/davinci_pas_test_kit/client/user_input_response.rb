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

    # Returns the nth response from a list of tester-provided responses for the must support workflow.
    # The input value should be a JSON array of response bundles, e.g., [bundle_1, bundle_2].
    # Returns nil if the input is not present, not parseable, or n exceeds the list length.
    def self.nth_user_inputted_response(result, operation, request_index)
      input_name = operation == 'submit' ? 'ms_submit_responses' : 'ms_inquire_responses'
      input_value = JSON.parse(result.input_json)&.find { |i| i['name'] == input_name }&.dig('value')
      return unless input_value.present?

      responses = JSON.parse(input_value)
      return unless responses.is_a?(Array) && request_index < responses.length

      responses[request_index].is_a?(String) ? responses[request_index] : responses[request_index].to_json
    rescue JSON::ParserError
      nil
    end

    def user_inputted_response?(input_key)
      return false if input_key.blank?
      return false unless respond_to?(input_key)

      public_send(input_key).present?
    end

    def input_title(input_key)
      config.inputs[input_key]&.title || config.inputs[input_key]&.name || input_key.to_s
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
