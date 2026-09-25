# frozen_string_literal: true

module DaVinciPASTestKit
  INPUT_CLIENT_ID_LOCKED =
    'The client\'s registered Client Id for use in obtaining access tokens. ' \
    'Run the **1** Client Registration group to configure this input.'
  INPUT_SESSION_URL_PATH_LOCKED =
    'The additional path used to create session-specific endpoints. Run the ' \
    '**1** Client Registration group to configure this input.'

  def self.ms_responses_input_description(operation)
    <<~DESCRIPTION
      A JSON list of objects ([format](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-option-format))
      that Inferno will use to respond to #{operation} requests during the
      *Must Support Elements* group. For each request, Inferno will
      [select](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-option-evaluation)
      and [instantiate](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
      a response to return from this list. If no entries match or instantiation fails, Inferno will
      [mock](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#mocked-responses)
      a response.
    DESCRIPTION
  end

  def self.user_response_input_description(operation, workflow, group_name)
    <<~DESCRIPTION
      If provided, this JSON will be [instantiated](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
      and sent in response to a #{operation} request received during the *#{group_name}* group to indicate
      that the request has been #{workflow}. If not provided or if instantiation fails,
      Inferno will [mock](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#mocked-responses)
      a response based on the submitted Claim and indicate it has been #{workflow}. In either
      case, the response will be validated against the PAS Response Bundle profile.
    DESCRIPTION
  end
end
