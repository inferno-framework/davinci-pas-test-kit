require 'subscriptions_test_kit'
require_relative 'pas_server_subscription_input_conformance'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASServerSubscriptionSetup < Inferno::TestGroup
      id :pas_server_v220_subscription_setup
      title 'Subscription Setup'
      description %(
          The Subscription Setup tests verify that the server supports creation of a rest-hook Subscription. The
          Subscription instance created in these tests will be used for a notification in the pended workflow tests
          later.
        )
      config inputs: { url: { name: :server_endpoint } }
      input_order :server_endpoint, :smart_credentials, :access_token, :subscription_resource
      run_as_group

      test from: :pas_server_v220_subscription_input_conformance do
        input :subscription_resource,
              title: 'Pended Prior Authorization Subscription',
              type: 'textarea',
              description: %(
                     A Subscription resource in JSON format that Inferno will send to the server under test so that it
                     can demonstrate its ability to notify Inferno when pended prior authorization requests have been
                     updated. The instance must be conformant to the R4/B Topic-Based Subscription profile. Inferno may
                     modify the Subscription before submission, e.g., to point to Inferno's notification endpoint.
                   )
      end
      test from: :subscriptions_r4_server_notification_delivery,
           title: 'Send Subscription and Receive Handshake Notification from Server',
           description: %(
               This test sends a request to create the Subscription resource to the Subscriptions Backport FHIR Server.
               If successful, it then waits for a handshake
               [notification](https://hl7.org/fhir/uv/subscriptions-backport/STU1.1/notifications.html#notifications).
               Other types of notifications, including heartbeat and event notifications, will be accepted by Inferno
               but ignored by this test group.
             )
      test from: :subscriptions_r4_server_creation_response_conformance
      test from: :subscriptions_r4_server_handshake_conformance
    end
  end
end
