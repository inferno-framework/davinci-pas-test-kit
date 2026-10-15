# frozen_string_literal: true

require 'subscriptions_test_kit'
require_relative 'subscription/pas_client_subscription_update_delete_test'
require_relative 'subscription/pas_client_subscription_put_update_pas_conformance_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubscriptionUpdateDeleteGroup < Inferno::TestGroup
      id :pas_client_v221_subscription_update_delete
      title 'Subscription Update and Deletion'
      description %(
        During this group, the tester will demonstrate the ability of the PAS client
        to update and delete the PAS Subscription instance that it created
        during the "Subscription Setup" group. This group must be run after
        all scenario and must support tests have been run as Inferno will
        not send notifications once the Subscription created during the
        "Subscription Setup" group has been modified or deleted during this
        group.

        Inferno will wait for the client to send update and delete requests and
        will then verify that the requests are conformant. Note that
        - Update and delete requests are only accepted by Inferno while
          this group is waiting.
        - Only requests for the Subscription created during the most recent
          run of the "Subscription Setup" group in this session will
          be accepted.
        - Once the Subscription has been deleted, Inferno will respond to
          further update and read requests for it with a `404 Not Found`
          until this group is re-run.
        - If this group is re-run, Inferno will forget about the previous
          update and delete interactions sent by the PAS client, including
          deletion. The PAS client can interact with the Subscription as it
          was after it was created. If the PAS client cannot resume
          interacting with a Subscription that it has deleted, re-run
          the *Subscription Setup* group to create a new Subscription.
      )
      run_as_group

      group 'Subscription Update and Delete Interaction' do
        id :pas_client_v221_subscription_update_delete_interaction
        test from: :pas_client_v221_subscription_update_delete_test
      end

      group 'Subscription Update and Delete Conformance' do
        id :pas_client_v221_subscription_update_delete_conformance
        test from: :subscriptions_r4_client_put_update_verification do
          title 'Subscription update requests have the correct structure and content'
        end
        test from: :pas_client_v221_subscription_put_update_pas_conformance_test
        test from: :subscriptions_r4_client_delete_verification do
          title 'Subscription delete requests have the correct structure and content'
        end
      end
    end
  end
end
