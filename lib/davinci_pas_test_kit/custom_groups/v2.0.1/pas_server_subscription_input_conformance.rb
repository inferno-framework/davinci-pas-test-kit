require_relative '../../pas_subscription_verification'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASServerSubscriptionInputConformance < Inferno::Test
      include PASSubscriptionVerification
      id :pas_server_subscription_input_conformance
      title '[USER INPUT VERIFICATION] Verify Subscription PAS conformance'
      description %(
        This test accepts a Subscription resource as an input and verifies that it is conformant to PAS requirements on
        the Subscriptions, including:
        - The payload content type must be `id-only`
        - The use of the [PAS-defined Subscription
          Topic](https://hl7.org/fhir/us/davinci-pas/STU2/SubscriptionTopic-PASSubscriptionTopic.html), and
        - Inclusion of filter criteria for the client's organization.
      )
      input :subscription_resource

      run do
        omit_if subscription_resource.blank?, 'Did not input a Subscription resource of this type.'
        verify_pas_subscription(subscription_resource)

        subscription = JSON.parse(subscription_resource)
        payload_ext = subscription.dig('channel', '_payload', 'extension')
        content_ext = payload_ext&.find do |ext|
          ext['url'] == 'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content'
        end

        payload_content = content_ext&.dig('valueCode')
        assert payload_content == 'id-only',
               "PAS Subscription payload content type is #{payload_content}, but must be id-only"
      end
    end
  end
end
