require_relative '../cross_suite/response_selection_utils'

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
    # JSON array of entries, where each entry is either a bare FHIR Bundle or Parameters
    # or a wrapper object holding the response resource under "bundle" alongside optional
    # selection "criteria" - see ResponseSelectionUtils.
    # Returns nil if the input has no value and raises InvalidInputError if the value
    # is present but unusable. The configurable (the waiting test) supplies the input
    # title so that the error names the input as the tester sees it.
    def self.response_candidates(configurable, operation, result)
      input_name = operation == 'submit' ? 'ms_submit_responses' : 'ms_inquire_responses'
      candidates(configurable, input_name, result, ResponseSelectionUtils::RESPONSE_RESOURCE_TYPES)
    end

    # Returns the tester-provided notification candidates for the must support workflow, in the same
    # format as response candidates (see response_candidates) except that each holds a notification Bundle.
    def self.notification_candidates(configurable, result)
      candidates(configurable, MS_NOTIFICATIONS_INPUT, result, NOTIFICATION_RESOURCE_TYPES)
    end

    MS_NOTIFICATIONS_INPUT = 'ms_submit_notifications'.freeze
    NOTIFICATION_RESOURCE_TYPES = ['Bundle'].freeze

    # Parses a must support candidate list input - see response_candidates.
    # @param resource_types [Array<String>] the resource types a candidate may hold.
    def self.candidates(configurable, input_name, result, resource_types)
      parse_candidates(configurable, input_name, read_input(result, input_name), resource_types)
    end

    # Parses the value of a must support candidate list input - see candidates.
    def self.parse_candidates(configurable, input_name, input_value, resource_types)
      return unless input_value.present?

      candidates = JSON.parse(input_value)
      candidates = [candidates] unless candidates.is_a?(Array)
      invalid_index = candidates.index { |candidate| !valid_candidate?(candidate, resource_types) }
      if invalid_index.present?
        raise InvalidInputError,
              "Entry #{invalid_index + 1} of the '#{input_title(configurable, input_name)}' input is not " \
              "a FHIR #{resource_types.join(' or ')} resource, or a wrapper object with one in the " \
              '"bundle" key.'
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

    def self.valid_candidate?(candidate, resource_types)
      return false unless candidate.is_a?(Hash)

      resource_types.include?(candidate['resourceType']) ||
        candidate[ResponseSelectionUtils::BUNDLE_KEY].is_a?(Hash)
    end

    def user_inputted_response?(input_key)
      input_key.present? && send(input_key).present?
    end

    def input_title(input_key)
      UserInputResponse.input_title(self, input_key)
    end

    def response_description_for_wait(user_input, user_input_title, operation)
      if user_input
        <<~DESCRIPTION.strip
          Inferno will respond to `#{operation}` requests with the content provided in the
          '**#{user_input_title}**' input, with `{{...}}` fhirpath expressions replaced with
          their value when evaluated against the request and timestamps and resources references
          updated to be current and consistent. See the ["Response Instantiation" section](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
          of the Da Vinci PAS Test Kit wiki for details on these updates.
        DESCRIPTION
      else
        <<~DESCRIPTION.strip
          Inferno will respond to `#{operation}` requests with a mocked response based on the request.
          See the ["Mocked Responses" section](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#mocked-responses)
          of the Da Vinci PAS Test Kit wiki for details on the mocked response.
        DESCRIPTION
      end
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
