# frozen_string_literal: true

module DaVinciPASTestKit
  INPUT_CLIENT_ID_LOCKED =
    'The client\'s registered Client Id for use in obtaining access tokens. ' \
    'Run the **1** Client Registration group to configure this input.'
  INPUT_SESSION_URL_PATH_LOCKED =
    'The additional path used to create session-specific endpoints. Run the ' \
    '**1** Client Registration group to configure this input.'
  INPUT_CLIENT_ENDPOINT_ACCESS_TOKEN =
    "The bearer token that Inferno will send on requests to the client system's rest-hook notification " \
    'endpoint. Not needed if the client system will create a Subscription with an appropriate header value ' \
    'in the `channel.header` element. If a value for the `authorization` header is provided in ' \
    '`channel.header`, this value will override it.'
  NOTIFICATION_TOKEN_AND_UPDATE_NOTE =
    'The notification JSON may include `{{fhirpath}}` tokens, evaluated against the submitted Claim ' \
    'bundle the same way as a tester-provided response body. Before sending, Inferno will also update ' \
    'the notification with details that the tester cannot know ahead of time, including timestamps ' \
    'corresponding to the notification trigger time, and the id of the triggering ClaimResponse if ' \
    'Inferno mocks that ClaimResponse because it is not provided by the tester.'

  def self.ms_responses_input_description(operation, supports_notification: false)
    notification_note = <<~NOTE if supports_notification

      An entry may also include a `"notification"` key to have Inferno send a Subscription event
      notification after returning that entry's response Bundle, as for a pended decision that is later
      finalized. Its value is either the string `"generate"`, to have Inferno generate the notification
      itself from the response Bundle, or a number giving the 1-based index of the entry
      from the *Must Support Notification Bodies* input to send instead.
    NOTE

    <<~DESCRIPTION
      A JSON list of objects ([format](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-option-format))
      that Inferno will use to respond to #{operation} requests during the
      *Must Support Elements* group. For each request, Inferno will
      [select](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-option-evaluation)
      and [instantiate](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
      a response to return from this list. If no entries match or instantiation fails, Inferno will
      [mock](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#mocked-responses)
      a response.
      #{notification_note}
    DESCRIPTION
  end

  def self.ms_notification_bodies_input_description
    <<~DESCRIPTION
      A JSON list of notification Bundles. When the entry Inferno selects from the *Must Support $submit
      Response Bundles* input has a `"notification"` value that is a number, Inferno sends the entry at
      that 1-based index from this list as the Subscription event notification following the selected
      $submit response. #{NOTIFICATION_TOKEN_AND_UPDATE_NOTE}
    DESCRIPTION
  end

  def self.notification_bundle_input_description(full_resource_required: false)
    full_resource_note = if full_resource_required
                           ' For PAS v2.2.1, the notification must be a full-resource notification ' \
                             'containing the complete ClaimResponse.'
                         end

    <<~DESCRIPTION
      If provided, this JSON will be sent as the notification for the
      PAS Subscription to tell the client that a decision has been made on the pended claim.
      #{NOTIFICATION_TOKEN_AND_UPDATE_NOTE}
      If not provided, a notification will be generated from the returned ClaimResponse.
      In either case the response will be validated to ensure that the notification
      is conformant.#{full_resource_note}
    DESCRIPTION
  end

  def self.user_response_input_description(operation, workflow, group_name)
    timing_description = "during the *#{group_name}* group to indicate that the request has been #{workflow}"
    user_response_input_description_base(operation, workflow, timing_description)
  end

  def self.user_response_input_description_for_update_tests(operation, default_decision, test_name)
    timing_description = "during the *#{test_name}* test in the *Claim Updates* group"
    user_response_input_description_base(operation, default_decision, timing_description)
  end

  def self.user_response_input_description_base(operation, workflow, timing_description)
    <<~DESCRIPTION
      If provided, this JSON will be [instantiated](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
      and sent in response to the #{operation} request received #{timing_description}.
      If not provided or if instantiation fails, Inferno will [mock](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#mocked-responses)
      the response based on the submitted Claim and indicate it has been #{workflow}. In either
      case, the response will be validated against the PAS Response Bundle profile.
    DESCRIPTION
  end
end
