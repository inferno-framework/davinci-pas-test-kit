require_relative '../../../urls'
require_relative '../../../descriptions'
require_relative '../../../user_input_response'
require_relative '../../../session_identification'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientDenialSubmitTest < Inferno::Test
      include URLs
      include SessionIdentification
      include UserInputResponse

      id :pas_client_v201_denial_submit_test
      title 'Client submits a claim using the $submit operation'
      description %(
        Inferno will wait for a prior authorization submission request
        from the client. Upon receipt, Inferno will respond with the
        provided denial response.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@58', 'hl7.fhir.us.davinci-pas_2.0.1@62',
                            'hl7.fhir.us.davinci-pas_2.0.1@70', 'hl7.fhir.us.davinci-pas_2.0.1@202'

      input :denial_json_response,
            title: 'Claim denied response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $submit requests during this test
              to indicate that the request has been denied.
              It will be updated to make creation timestamps current.
              If not provided, a denial response will be generated from the submitted Claim.
              In either case, the response will be validated against the PAS Response Bundle profile.
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
      submit_respond_with :denial_json_response

      run do
        if user_inputted_response? :denial_json_response
          assert_valid_json denial_json_response,
                            'Input "Claim denied response JSON" must be valid JSON'
        else
          add_message('info', %(
            No denied response provided in input '#{input_title(:denial_json_response)}'. Any responses to $submit
            requests will be generated by Inferno from the submitted Claim.
          ))
        end

        wait_identifier = session_wait_identifier(client_id, session_url_path)
        submit_endpoint = session_endpont_url(:submit, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: %(
            **Denial Workflow Test**:

            Submit a PAS request to

            `#{submit_endpoint}`

            If the optional '**#{input_title(:denial_json_response)}**' input is populated, it will
            be returned, updated with current timestamps. Otherwise, a denial response will
            be generated by Inferno using the received Claim.
          )
        )
      end
    end
  end
end
