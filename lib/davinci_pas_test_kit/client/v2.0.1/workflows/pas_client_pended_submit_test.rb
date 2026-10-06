require_relative '../urls'
require_relative '../../client_input_descriptions'
require_relative '../../user_input_response'
require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../session_identification'
require_relative '../../subscription_setup_requirement'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedSubmitTest < Inferno::Test
      include URLs
      include SessionIdentification
      include UserInputResponse
      include PasBundleValidation
      include SubscriptionSetupRequirement

      id :pas_client_v201_pended_submit_test
      title 'Client submits a claim and reacts to a pended response'
      description %(
        During this test, Inferno will wait for a prior authorization submission request
        from the client. Upon receipt, Inferno will respond with the
        provided pended response. Subsequently, Inferno will send a
        notification that the claim has been finalized and expect the
        client system to send a follow-up inquiry.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@58', 'hl7.fhir.us.davinci-pas_2.0.1@62',
                            'hl7.fhir.us.davinci-pas_2.0.1@67', 'hl7.fhir.us.davinci-pas_2.0.1@70',
                            'hl7.fhir.us.davinci-pas_2.0.1@119', 'hl7.fhir.us.davinci-pas_2.0.1@120',
                            'hl7.fhir.us.davinci-pas_2.0.1@153', 'hl7.fhir.us.davinci-pas_2.0.1@202',
                            'hl7.fhir.us.davinci-pas_2.0.1@203'

      config options: { accepts_multiple_requests: true, submit_enabled: true, inquire_enabled: true }
      input :notification_bundle,
            title: 'Claim updated notification JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent as the notification for the
              PAS Subscription to tell the client that a decision has been made on the pended claim.
              Before sending, Inferno will update the provided notification with details that the tester cannot
              know ahead of time, including timestamps corresponding to the notification trigger time, and the id of
              the triggering ClaimResponse if Inferno mocks that ClaimResponse because it is not provided by the
              tester through the *Claim pended response JSON* input.
              If not provided, a notification will be generated from the returned ClaimResponse.
              In either case the response will be validated to ensure that the notification
              is conformant.
            )
      input :pended_json_response,
            title: 'Claim pended response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $submit requests during this test
              to indicate that the request has been pended awaiting a final decision.
              It will be updated to make creation timestamps current.
              If not provided, a pended response will be generated from the submitted Claim.
              In either case the response will be validated against the PAS Response Bundle profile.
            )
      input :inquire_json_response,
            title: 'Inquire approved response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $inquire requests during this test
              to indicate that the request has been approved.
              It will be updated to make creation timestamps current.
              If not provided, an approval response will be generated from the submitted Claim.
              In either case, the response will be validated against the PAS Response Bundle profile.
            )
      input :client_endpoint_access_token,
            optional: true,
            title: 'Client Notification Access Token',
            description: %(
              The bearer token that Inferno will send on requests to the client system's rest-hook notification
              endpoint. Not needed if the client system will create a Subscription with an appropriate header value
              in the `channel.header` element. If a value for the `authorization` header is provided in
              `channel.header`, this value will override it.
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
      output :confirmation_url

      submit_respond_with :pended_json_response
      inquire_respond_with :inquire_json_response

      run do
        require_successful_subscription_create_request

        if user_inputted_response? :pended_json_response
          assert_valid_json pended_json_response,
                            "Input '#{input_title(:pended_json_response)}' must be valid JSON"
        else
          add_message('info', %(
            No pended response provided in input '#{input_title(:pended_json_response)}'. Any responses to $submit
            requests will be generated by Inferno from the submitted Claim.
          ))
        end

        if user_inputted_response? :inquire_json_response
          assert_valid_json inquire_json_response,
                            "Input '#{input_title(:inquire_json_response)}' must be valid JSON"
        else
          add_message('info', %(
            No inquire response provided in input '#{input_title(:inquire_json_response)}'. Any responses to $inquire
            requests will be generated by Inferno from the inquired Claim.
          ))
        end

        if notification_bundle.present?
          assert_valid_json notification_bundle,
                            "Input '#{input_title(:notification_bundle)}' must be valid JSON"
        else
          add_message('info', %(
            No notification body provided in input '#{input_title(:notification_bundle)}'. When sending a
            notification finalizing a pended $submit response, the notification body will be generated by Inferno
            from the submitted Claim.
          ))
        end

        wait_identifier = session_wait_identifier(client_id, session_url_path)
        submit_endpoint = session_endpoint_url(:submit, client_id, session_url_path)
        inquire_endpoint = session_endpoint_url(:inquire, client_id, session_url_path)

        confirmation_url = "#{resume_pass_url}?token=#{wait_identifier}"
        output(confirmation_url:)

        wait(
          identifier: wait_identifier,
          timeout: 600,
          message: <<~MESSAGE
            **Pended Scenario Test**:

            Inferno will wait while the tester uses the client system to complete the following steps:

            1. Submit a PAS request to Inferno's `$submit` endpoint. Inferno will return a pended response.
            2. Within 5-10 seconds, Inferno will send a notification indicating that the ClaimResponse has
               been finalized to the endpoint provided on the Subscription during the _Subscription Setup_ tests.
            3. Once the notification has been received, submit a PAS inquiry request to Inferno's `$inquire`
               endpoint. Inferno will return an approval response.

            Inferno will later ask testers to attest that the system marked the request as pended after
            step 1 (submit) and before step 2 (notification), so testers should check their system state
            between these steps in order to faithfully answer the attestation.

            [Click here](#{confirmation_url}) once the client has completed these steps.

            ### Endpoints

            - $submit: `#{submit_endpoint}`
            - $inquire: `#{inquire_endpoint}`

            ### Authentication and Identification

            #{auth_description_for_wait(client_id)}

            ### Responses

            #{response_description_for_wait(user_inputted_response?(:pended_json_response),
                                            input_title(:pended_json_response),
                                            '$submit')}

            #{response_description_for_wait(user_inputted_response?(:inquire_json_response),
                                            input_title(:inquire_json_response),
                                            '$inquire')}

            #{notification_description_for_wait}
          MESSAGE
        )
      end

      def notification_description_for_wait
        if notification_bundle.present?
          "Inferno will send the content of the '**#{input_title(:notification_bundle)}**' input as the " \
            'notification, updated with current timestamps.'
        else
          'Inferno will send a notification generated from the pended response.'
        end
      end
    end
  end
end
