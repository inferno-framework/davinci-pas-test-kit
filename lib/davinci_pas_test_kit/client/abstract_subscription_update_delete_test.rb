require_relative 'client_input_descriptions'
require_relative 'session_identification'
require_relative 'subscription_setup_requirement'

module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractSubscriptionUpdateDeleteTest < Inferno::Test
    include SessionIdentification
    include SubscriptionSetupRequirement

    id :pas_client_subscription_update_delete_test
    title 'PAS client submits Subscription update and deletion requests'
    description %(
      During this test, Inferno will wait for Subscription update and deletion requests
      for the PAS Subscription created during the "Subscription Setup" group.

      Additional notes:
      - Updated Subscriptions must meet PAS Subscription requirements.
      - Inferno will not send additional notifications or handshakes based on the updated Subscription.
      - Inferno will modify the `Subscription.channel.payload` value on the updated Subscription to
        `application/fhir+json` unless it is `application/json`.
      - Inferno manages the `Subscription.status` value and will ignore requested changes to it, unless
        the requested status is `off`.
      - Inferno only accepts updates and deletes of the Subscription while this test is waiting.
      - Each run of this test starts from the Subscription as created during the "Subscription Setup"
        group. Changes made during earlier runs of this test, including deletion, are not carried over.
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

    config options: { accepts_subscription_changes: true }

    run do
      subscription_request = require_successful_subscription_create_request(skip_message: UPDATE_DELETE_SKIP_MESSAGE)
      subscription_id = JSON.parse(subscription_request.response_body)['id']

      wait_identifier = session_wait_identifier(client_id, session_url_path)
      subscription_endpoint = session_endpoint_url(:subscription, client_id, session_url_path)
      confirmation_url = "#{resume_pass_url}?token=#{wait_identifier}"
      output(confirmation_url:)

      wait(
        identifier: wait_identifier,
        message: <<~MESSAGE
          **Subscription Update and Deletion Tests**:

          Inferno will wait while the tester uses the client system to update and delete the PAS
          Subscription created earlier in these tests. Updated Subscriptions must continue to meet
          the PAS Subscription requirements, but Inferno will not use them to deliver notifications.

          [Click here](#{confirmation_url}) when all requests have been submitted.

          ### Endpoints

          Submit [update](https://hl7.org/fhir/R4/http.html#update) (PUT) and
          [delete](https://hl7.org/fhir/R4/http.html#delete) (DELETE) interaction
          requests for the Subscription with id `#{subscription_id}` to:

          `#{subscription_endpoint}/#{subscription_id}`

          ### Authentication and Identification

          #{auth_description_for_wait(client_id)}

        MESSAGE
      )
    end
  end
end
