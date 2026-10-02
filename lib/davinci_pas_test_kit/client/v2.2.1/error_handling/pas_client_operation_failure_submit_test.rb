require_relative '../urls'
require_relative '../../../client/client_input_descriptions'
require_relative '../../../client/user_input_response'
require_relative '../../../client/session_identification'
require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientOperationFailureSubmitTest < Inferno::Test
      include URLs
      include SessionIdentification
      include UserInputResponse

      id :pas_client_v221_operation_failure_submit_test
      title 'PAS client submits a claim and receives an OperationOutcome response'
      description %(
        During this test, Inferno will wait for a prior authorization submission request from the client.
        Upon receipt, Inferno will return the provided OperationOutcome with the configured
        HTTP status code (default 400).
      )

      input :operation_failure_operation_outcome,
            title: 'Operation Failure OperationOutcome JSON',
            type: 'textarea',
            description: %(
              Inferno will return exactly this OperationOutcome JSON in response
              to the $submit request during the *Operation Failure* group.
            )
      input :operation_failure_http_status,
            title: 'Operation Failure HTTP Status Code',
            type: 'text',
            optional: true,
            default: '400',
            description: %(
              The HTTP status code Inferno will use when returning the Operation Failure
              OperationOutcome to the client. If provided, the value ust be in the 4XX or
              5XX range. Inferno will return 400 if this input is not provided or the
              provided value is outside that range.
            )
      input :client_id,
            title: 'Client Id',
            type: 'text',
            optional: true,
            locked: true,
            description: INPUT_CLIENT_ID_LOCKED
      input :session_url_path,
            title: 'Session-specific URL path extension',
            type: 'text',
            optional: true,
            locked: true,
            description: INPUT_SESSION_URL_PATH_LOCKED

      submit_respond_with :operation_failure_operation_outcome
      config options: { submit_enabled: true }

      run do
        assert_valid_json operation_failure_operation_outcome,
                          "Input '#{input_title(:operation_failure_operation_outcome)}' must be valid JSON."

        wait_identifier = session_wait_identifier(client_id, session_url_path)
        submit_endpoint = session_endpoint_url(:submit, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: <<~MESSAGE
            **Operation Failure Scenario Test**:

            Inferno will wait while the tester uses the client system to submit a PAS request to
            Inferno. Inferno will respond with exactly the provided OperationOutcome and HTTP status.
            The tests will automatically continue once a request has been received.

            ### Endpoints

            Submit a PAS request to

            `#{submit_endpoint}`

            ### Authentication and Identification

            #{auth_description_for_wait(client_id)}
          MESSAGE
        )
      end
    end
  end
end
