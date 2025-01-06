require_relative '../../../urls'
require_relative '../../../user_input_response'
require_relative '../../../pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedSubmitTest < Inferno::Test
      include URLs
      include UserInputResponse
      include PasBundleValidation

      id :pas_client_v201_pended_submit_test
      title 'Client submits a claim and reacts to a pended response'
      description %(
        Inferno will wait for a prior authorization submission request
        from the client. Upon receipt, Inferno will respond with the
        provided pended response. Subsequently, Inferno will send a
        notification that the claim has been finalized and expect the
        client under test to send a follow-up inquiry.
      )
      config options: { accepts_multiple_requests: true }
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )
      input :notification_bundle
      input :client_endpoint_access_token,
            optional: true,
            title: 'Client Notification Access Token',
            description: %(
              The bearer token that Inferno will send on requests to the client under test's rest-hook notification
              endpoint. Not needed if the client under test will create a Subscription with an appropriate header value
              in the `channel.header` element. If a value for the `authorization` header is provided in
              `channel.header`, this value will override it.
            )
      respond_with :pended_json_response

      run do
        check_user_inputted_response :pended_json_response

        load_tagged_requests(SUBSCRIPTION_CREATE_TAG)
        skip_if requests.empty?,
                %(
                  No Subscription exists to receive notifications for pended claims. Run the _PAS Subscription Setup_
                  tests to provide a Subscription for use in delivering notifications.
                )

        wait(
          identifier: access_token,
          message: %(
            **Pended Workflow Test**:

            1. Submit a PAS request to

            `#{submit_url}`

            The pended response provided in the '**#{input_title(:pended_json_response)}**' input will be returned.

            2. Within 5-10 seconds, Inferno will send a notification indicating that the ClaimResponse has been
               finalized. To do so, Inferno will send the notification body provided in the
               '**#{input_title(:notification_bundle)}**' input to the endpoint provided on the Subscription during the
               _PAS Subscription Setup_ tests.

            3. Once the notification has been received, submit an inquiry request to get the details on the
               updated ClaimResponse. Inferno will return an approved response.

            Note that Inferno will ask testers to attest to correct behavior of the system between these steps,
            e.g., that the system marked the pended prior auth request appropriately after step 1 (submit) but
            before step 2 (notification). Thus testers should check their system state as appropriate in order
            to be able to faithfully answer the attestations.

            Once the client has completed these steps,
            [click here to complete the test](#{resume_pass_url}?token=#{access_token})
            and continue Inferno's evaluation of the interaction.
          )
        )
      end
    end
  end
end
