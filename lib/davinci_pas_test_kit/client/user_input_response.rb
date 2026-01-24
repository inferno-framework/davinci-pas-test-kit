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

    def user_inputted_response?(input_key)
      send(input_key).present?
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
