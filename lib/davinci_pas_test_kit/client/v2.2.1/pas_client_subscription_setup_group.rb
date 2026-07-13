require 'subscriptions_test_kit'
require_relative 'subscription/pas_client_subscription_create_test'
require_relative '../pas_client_subscription_pas_conformance_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubscriptionSetupGroup < Inferno::TestGroup
      id :pas_client_v221_subscription_setup
      title 'Subscription Setup'
      description %(
        These tests verify that the client can create a Subscription instance
        that will tell the Payer how to notify the client when pended claims
        are updated.
      )
      run_as_group

      test from: :pas_client_v221_subscription_create_test
      test from: :pas_client_subscription_pas_conformance_test,
           description: %(
             This test verifies that the Subscription created by the client under test
             is conformant to PAS requirements on the Subscription, including
             - The use of the [PAS-defined Subscription
               Topic](https://hl7.org/fhir/us/davinci-pas/2.2.1/SubscriptionTopic-PASSubscriptionTopic.html), and
             - Inclusion of filter criteria for the client's organization.
           ),
           config: { options: { ig_version: 'v2.2.1' } }
      test from: :subscriptions_r4_client_handshake_notification_verification,
           title: "PAS client responds correctly to Inferno's Subscription handshake"
    end
  end
end
