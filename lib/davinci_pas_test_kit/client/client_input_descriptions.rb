# frozen_string_literal: true

module DaVinciPASTestKit
  INPUT_CLIENT_ID_LOCKED =
    'The client\'s registered Client Id for use in obtaining access tokens. ' \
    'Run the **1** Client Registration group to configure this input.'
  INPUT_SESSION_URL_PATH_LOCKED =
    'The additional path used to create session-specific endpoints. Run the ' \
    '**1** Client Registration group to configure this input.'

  # Shared text for the "Demonstrate Must Support Coverage" group and its combined $submit/$inquire
  # response_attest test, identical across PAS versions in each client/vX/pas_client_must_support_group.rb
  # other than the requirement each version's attest test verifies.
  MUST_SUPPORT_RECEIVE_GROUP_TITLE = 'Demonstrate Must Support Coverage'
  MUST_SUPPORT_RECEIVE_GROUP_DESCRIPTION =
    %(
      During this group, Inferno will wait while the tester uses the client system to
      make `$submit` and `$inquire` operation requests to Inferno demonstrating coverage
      of must support elements not yet demonstrated.

      Inferno then asks for confirmation that all responses were handled
      without error and verifies the conformance of all requests and responses.
    )
  MUST_SUPPORT_SUBMIT_INQUIRE_ATTEST_TITLE =
    'PAS client handled the $submit and $inquire responses without erroring'
  MUST_SUPPORT_SUBMIT_INQUIRE_ATTEST_DESCRIPTION =
    %(
      During this test, the tester will verify that the client handled
      the `$submit` and `$inquire` operation responses, making the result available to
      the user without failing or erroring.
    )
  MUST_SUPPORT_SUBMIT_INQUIRE_ATTEST_MESSAGE =
    'I attest that the client system correctly handled the `$submit` and `$inquire` ' \
    'operation responses received from Inferno during this test, making the details ' \
    'available to users without errors.'

  def self.must_support_group_description(ig_version, wiki_anchor)
    <<~DESCRIPTION
      During these tests, Inferno will check that the client system demonstrates support for
      all required profiles and must support elements. When looking for demonstration of
      these profiles and elements, Inferno will consider requests and responses from
      interactions performed during the PAS scenario group as well as additional ones
      made when executing this group.

      For additional details on these tests, what they check for, and the requirements
      underlying them, see the ["Client Must Support Tests" section](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support)
      of the Da Vinci PAS Test Kit wiki, specifically
      - [Which messages Inferno considers when looking for demonstration of must support elements](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support#evaluated-messages).
      - [What clients must demonstrate to pass these #{ig_version} client must support tests](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support##{wiki_anchor}).
    DESCRIPTION
  end

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
