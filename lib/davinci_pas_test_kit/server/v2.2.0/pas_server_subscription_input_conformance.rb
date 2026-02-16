require_relative '../../cross_suite/pas_subscription_verification'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASServerSubscriptionInputConformance < Inferno::Test
      include PASSubscriptionVerification
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

      run do
        omit_if subscription_resource.blank?, 'Did not input a Subscription resource of this type.'
        verify_pas_subscription(subscription_resource, ig_version: 'v2.2.0')
      end
    end
  end
end
