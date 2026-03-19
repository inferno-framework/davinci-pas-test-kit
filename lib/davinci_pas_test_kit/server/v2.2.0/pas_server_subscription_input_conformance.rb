require_relative '../../cross_suite/pas_subscription_verification'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASServerSubscriptionInputConformance < Inferno::Test
      include PASSubscriptionVerification
      include SubscriptionsTestKit::SubscriptionConformanceVerification
      id :pas_server_v220_subscription_input_conformance
      title '[USER INPUT VERIFICATION] Verify Subscription PAS conformance'
      description %(
        This test accepts a Subscription resource as an input and verifies that it is conformant to PAS requirements on
        the Subscriptions, including:
        - The payload content type must be `full-resource`
        - Conformance to the [PAS Subscription
          profile](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-subscription)
        - The channel type is `rest-hook`
        - Inclusion of filter criteria for the client's organization.
      )
      input :subscription_resource
      input :access_token,
            title: 'Notification Access Token',
            description: %(
              An access token that the server under test will send to Inferno on notifications
              so that the request gets associated with this test session. The token must be
              provided as a `Bearer` token in the `Authorization` header of HTTP requests
              sent to Inferno.
            )

      output :updated_subscription

      run do
        omit_if subscription_resource.blank?, 'Did not input a Subscription resource of this type.'

        assert_valid_json(subscription_resource)
        subscription = JSON.parse(subscription_resource)
        server_check_channel(subscription, access_token)

        updated_subscription = subscription.to_json
        output(updated_subscription:)

        verify_pas_subscription(updated_subscription, ig_version: 'v2.2.0')
      end
    end
  end
end
