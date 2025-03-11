require_relative '../../../urls'
require_relative '../../../descriptions'
require_relative '../../../session_identification'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubscriptionCreateTest < Inferno::Test
      include URLs
      include SessionIdentification

      id :pas_client_v201_subscription_create_test
      title 'Client submits a Subscription Creation Request'
      description %(
        Inferno will wait for a Subscription Creation request
        and then perform a handshake to activate the Subscription.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@137', 'hl7.fhir.us.davinci-pas_2.0.1@140',
                            'hl7.fhir.us.davinci-pas_2.0.1@142'

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
              The bearer token that Inferno will send on requests to the client under test's rest-hook notification
              endpoint, including handshake notifications sent after Subscription creation. Not needed if the client
              under test will create a Subscription with an appropriate header value in the `channel.header` element.
              If a value for the `authorization` header is provided in `channel.header`, this value will override it.
            )

      run do
        wait_identifier = inputs_to_wait_identifier(client_id, session_url_path)
        subscription_endpoint = inputs_to_session_endpont(:subscription, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: %(
            **Subscription Creation Test**:

            Submit a POST with a Subscription to:

            `#{subscription_endpoint}`

            Upon receipt, Inferno will send a handshake request to verify that notifications can be
            delivered and continue the test with a pass or fail based on the result.
          )
        )
      end
    end
  end
end
