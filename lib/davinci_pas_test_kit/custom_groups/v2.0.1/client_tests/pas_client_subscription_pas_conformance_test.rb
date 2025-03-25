# frozen_string_literal: true

require_relative '../../../pas_subscription_verification'

module DaVinciPASTestKit
  module DaVinciPASV201
    class SubscriptionPASConformanceTest < Inferno::Test
      include PASSubscriptionVerification

      id :pas_client_v201_subscription_pas_conformance_test
      title 'Client Subscription PAS Conformance Verification'
      description %(
        This test verifies that the Subscription created by the client under test
        is conformant to PAS requirements on the Subscription, including
        - The use of the [PAS-defined Subscription
          Topic](https://hl7.org/fhir/us/davinci-pas/STU2/SubscriptionTopic-PASSubscriptionTopic.html), and
        - Inclusion of filter criteria for the client's organization.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@143'

      run do
        load_tagged_requests(SUBSCRIPTION_CREATE_TAG)
        skip_if(requests.none?, 'Inferno did not receive a Subscription creation request')
        subscription_resource = request.request_body

        verify_pas_subscription(subscription_resource)
      end
    end
  end
end
