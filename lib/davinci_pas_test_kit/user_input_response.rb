module DaVinciPASTestKit
  module UserInputResponse
    def self.included(klass)
      klass.extend ClassMethods
    end

    def self.user_inputted_response(configurable, result)
      input_key = configurable.config.options[:respond_with]
      return unless input_key.present?

      JSON.parse(result.input_json)&.find { |i| i['name'] == input_key.to_s }&.dig('value')
    rescue JSON::ParserError
      nil
    end

    def check_user_inputted_response(input_key, message = nil)
      skip_if send(input_key).blank?,
              message ||
              "To run this test a response body must be provided in the '**#{input_title(input_key)}**' input"
    end

    def input_title(input_key)
      config.inputs[input_key]&.title || config.inputs[input_key]&.name
    end

    module ClassMethods
      def respond_with(key)
        config options: { respond_with: key }
      end
    end
  end
end
