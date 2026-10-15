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
      subscription_id = require_created_subscription(skip_message: UPDATE_DELETE_SKIP_MESSAGE)['id']

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
          [Inferno](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Subscriptions-and-Notifications#subscription-validation)
          and PAS Subscription requirements, but Inferno will not use the updated Subscription to deliver
          notifications, including updated handshakes.

          [Click here](#{confirmation_url}) when all requests have been submitted.

          ### Endpoints

          Submit [update](https://hl7.org/fhir/R4/http.html#update) (PUT) and
          [delete](https://hl7.org/fhir/R4/http.html#delete) (DELETE) interaction
          requests for the Subscription with id `#{subscription_id}` to:

          `#{subscription_endpoint}/#{subscription_id}`

          Inferno will also respond to [read](https://hl7.org/fhir/R4/http.html#read) (GET)
          interactions and `$status` operation calls for this Subscription.

          ### Authentication and Identification

          #{auth_description_for_wait(client_id)}

          ### Responses

          The PAS Test Kit wiki contains details on the supported responses
          that the PAS client can expect to receive during these tests:
          - [Subscription update responses](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Subscriptions-and-Notifications#update-response)
          - [Subscription deletion responses](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Subscriptions-and-Notifications#deletion-response)
        MESSAGE
      )
    end
  end
end
