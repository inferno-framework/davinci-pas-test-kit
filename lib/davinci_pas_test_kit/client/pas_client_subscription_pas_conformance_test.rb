# frozen_string_literal: true

require_relative '../cross_suite/pas_subscription_verification'

module DaVinciPASTestKit
  class SubscriptionPASConformanceTest < Inferno::Test
    include PASSubscriptionVerification

    id :pas_client_subscription_pas_conformance_test
    title 'Client Subscription PAS Conformance Verification'
    description %(
      This test verifies that the Subscription created by the client under test
      is conformant to PAS requirements on the Subscription, including
      - The use of the [PAS-defined Subscription
        Topic](https://hl7.org/fhir/us/davinci-pas/STU2/SubscriptionTopic-PASSubscriptionTopic.html), and
      - Inclusion of filter criteria for the client's organization.
    )

    def ig_version
      config.options[:ig_version]
    end

    run do
      load_tagged_requests(SUBSCRIPTION_CREATE_TAG)
      skip_if(requests.none?, 'Inferno did not receive a Subscription creation request')
      subscription_resource = request.request_body

      verify_pas_subscription(subscription_resource, ig_version:)
    end
  end
end
