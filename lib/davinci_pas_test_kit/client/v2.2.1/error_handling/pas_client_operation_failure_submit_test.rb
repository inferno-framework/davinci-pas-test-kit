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
      title 'Client submits a claim and handles an operation failure (OperationOutcome) response'
      description %(
        Inferno will wait for a prior authorization submission request from the client.
        Upon receipt, Inferno will return the provided OperationOutcome with the configured
        HTTP status code (default 400).
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@38', 'hl7.fhir.us.davinci-pas_2.2.1@39',
                            'hl7.fhir.us.davinci-pas_2.2.1@40', 'hl7.fhir.us.davinci-pas_2.2.1@41'

      input :operation_failure_operation_outcome,
            title: 'Operation Failure OperationOutcome JSON',
            type: 'textarea',
            description: %(
              Inferno will return this OperationOutcome JSON in response to the $submit request
              during this test.
            )
      input :operation_failure_http_status,
            title: 'Operation Failure HTTP Status Code',
            type: 'text',
            optional: true,
            default: '400',
            description: %(
              The HTTP status code Inferno will use when returning the OperationOutcome to the client.
              Must be a 4XX or 5XX value. Defaults to 400 if not provided or outside that range.
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

      run do
        assert_valid_json operation_failure_operation_outcome,
                          "Input '#{input_title(:operation_failure_operation_outcome)}' must be valid JSON."

        wait_identifier = session_wait_identifier(client_id, session_url_path)
        submit_endpoint = session_endpont_url(:submit, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: %(
            **Operation Failure Workflow Test**:

            Submit a PAS request to

            `#{submit_endpoint}`

            Inferno will respond with the provided OperationOutcome and HTTP status
            **#{operation_failure_http_status.present? ? operation_failure_http_status : '400'}**.
          )
        )
      end
    end
  end
end
