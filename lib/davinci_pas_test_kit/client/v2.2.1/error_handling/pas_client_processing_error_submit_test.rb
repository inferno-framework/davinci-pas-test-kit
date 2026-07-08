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
      title 'Client submits a claim and handles a response containing processing errors'
      description %(
        Inferno will wait for a prior authorization submission request from the client.
        Upon receipt, Inferno will return the provided response bundle containing one or
        more ClaimResponse.error entries.
      )

      input :processing_error_response,
            title: 'Processing Error Response Bundle JSON',
            type: 'textarea',
            description: %(
              Inferno will return this PAS Response Bundle JSON in response to the $submit request
              during this test. The bundle must contain at least one ClaimResponse.error entry.
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
          message: %(
            **Processing Error Workflow Test**:

            Submit a PAS request to

            `#{submit_endpoint}`

            Inferno will respond with the provided PAS Response Bundle containing
            ClaimResponse.error entries.
          )
        )
      end
    end
  end
end
