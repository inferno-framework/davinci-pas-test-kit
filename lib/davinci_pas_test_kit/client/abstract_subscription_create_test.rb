require_relative 'client_input_descriptions'
require_relative 'session_identification'

module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractSubscriptionCreateTest < Inferno::Test
    include SessionIdentification

    id :pas_client_subscription_create_test
    title 'PAS client submits a Subscription creation request'
    description %(
      During this test, Inferno will wait for a Subscription creation request
      and then perform a handshake to activate the Subscription.
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
    input :client_endpoint_access_token,
          optional: true,
          title: 'Client Notification Access Token',
          description: %(
            The bearer token that Inferno will send on requests to the client system's rest-hook notification
            endpoint, including handshake notifications sent after Subscription creation. Not needed if the client
            under test will create a Subscription with an appropriate header value in the `channel.header` element.
            If a value for the `authorization` header is provided in `channel.header`, this value will override it.
          )

    run do
      wait_identifier = session_wait_identifier(client_id, session_url_path)
      subscription_endpoint = session_endpoint_url(:subscription, client_id, session_url_path)

      wait(
        identifier: wait_identifier,
        message: <<~MESSAGE
          **Subscription Creation Test**:

          Inferno will wait while the tester uses the client system to create a Subscription on
          Inferno's simulated payer server. Inferno [will not accept all Subscriptions](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Subscriptions-and-Notifications#subscription-validation)
          but a Subscription does not need to be fully conformant to be accepted.

          After accepting a Subscription, Inferno will send a handshake notification
          to the specified `channel.endpoint` and continue automatically.

          ### Endpoints

          Submit a POST with a Subscription to

          `#{subscription_endpoint}`

          ### Authentication and Identification

          #{auth_description_for_wait(client_id)}

          ### Responses and Handshake Notifications

          The PAS Test Kit wiki contains details on the supported responses and
          notifications that the client system can expect to receive during these tests:
          - [Subscription creation responses](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Subscriptions-and-Notifications#creation-response)
          - [Handshake notification](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Subscriptions-and-Notifications#handshake-notification)
        MESSAGE
      )
    end
  end
end
