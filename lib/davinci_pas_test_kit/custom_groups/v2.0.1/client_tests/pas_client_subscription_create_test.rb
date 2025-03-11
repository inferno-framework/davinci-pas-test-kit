require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubscriptionCreateTest < Inferno::Test
      include URLs

      id :pas_client_v201_subscription_create_test
      title 'Client submits a Subscription Creation Request'
      description %(
        Inferno will wait for a Subscription Creation request
        and then perform a handshake to activate the Subscription.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@137', 'hl7.fhir.us.davinci-pas_2.0.1@140',
                            'hl7.fhir.us.davinci-pas_2.0.1@142', 'hl7.fhir.us.davinci-pas_2.0.1@144'

      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )
      input :client_endpoint_access_token,
            optional: true,
            title: 'Client Notification Access Token',
            description: %(
              The bearer token that Inferno will send on requests to the client under test's rest-hook notification
              endpoint. Not needed if the client under test will create a Subscription with an appropriate header value
              in the `channel.header` element. If a value for the `authorization` header is provided in
              `channel.header`, this value will override it.
            )

      run do
        wait(
          identifier: access_token,
          message: %(
            **Subscription Creation Test**:

            Submit a POST with a Subscription to:

            `#{fhir_subscription_url}`

            The request must have an `Authorization` header with the value `Bearer #{access_token}`.

            Upon receipt, Inferno will send a handshake request to verify that notifications can be
            delivered and continue the test with a pass or fail based on the result.
          )
        )
      end
    end
  end
end
