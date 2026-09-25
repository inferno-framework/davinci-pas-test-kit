require_relative '../urls'
require_relative '../../../client/client_input_descriptions'
require_relative '../../../client/user_input_response'
require_relative '../../../client/session_identification'
require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientProcessingErrorSubmitTest < Inferno::Test
      include URLs
      include SessionIdentification
      include UserInputResponse

      id :pas_client_v221_processing_error_submit_test
      title 'PAS client submits a claim and receives a response containing processing errors'
      description %(
        Inferno will wait for a prior authorization submission request from the client.
        Upon receipt, Inferno will return the provided response bundle containing one or
        more ClaimResponse.error entries.
      )

      input :processing_error_response,
            title: 'Processing Error Response Bundle JSON',
            type: 'textarea',
            description: %(
              Inferno will [instantiate](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
              this PAS Response Bundle JSON and return it as the response
              to the `$submit` request received during the *Processing Errors* group.
              The bundle must contain at least one ClaimResponse.error entry.
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

      submit_respond_with :processing_error_response

      run do
        assert_valid_json processing_error_response,
                          "Input '#{input_title(:processing_error_response)}' must be valid JSON."

        wait_identifier = session_wait_identifier(client_id, session_url_path)
        submit_endpoint = session_endpoint_url(:submit, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: <<~MESSAGE
            **Processing Error Workflow Test**:

            Inferno will wait while the tester uses the system to submit a PAS request to
            Inferno. Inferno will [instantiate](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
            the provided Processing Error Response Bundle and respond with it.
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
