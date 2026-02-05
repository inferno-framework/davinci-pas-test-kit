require 'subscriptions_test_kit'
require_relative 'subscription/pas_client_subscription_create_test'
require_relative '../pas_client_subscription_pas_conformance_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientSubscriptionSetupGroup < Inferno::TestGroup
      id :pas_client_v220_subscription_setup
      title 'Subscription Setup'
      description %(
        These tests verify that the client can create a Subscription instance
        that will tell the Payer how to notify the client when pended claims
        are updated.
      )
      run_as_group

      test from: :pas_client_v220_subscription_create_test
      test from: :subscriptions_r4_client_subscription_verification
      test from: :pas_client_subscription_pas_conformance_test,
           config: { options: { ig_version: 'v2.2.0' } }
      test from: :subscriptions_r4_client_handshake_notification_verification
    end
  end
end
