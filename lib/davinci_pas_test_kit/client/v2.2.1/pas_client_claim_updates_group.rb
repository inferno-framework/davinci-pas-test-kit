require_relative 'workflows/pas_client_claim_update_submit_tests'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_claim_update_referenced_claim_test'
require_relative 'workflows/pas_client_claim_update_grandparent_excluded_test'
require_relative 'workflows/pas_client_claim_update_referenced_resources_test'
require_relative 'workflows/pas_client_claim_update_entries_preserved_test'
require_relative 'workflows/pas_client_claim_update_cancelled_entries_test'
require_relative 'workflows/pas_client_claim_update_cancelled_items_certtype_test'
require_relative 'workflows/pas_client_claim_update_changed_entries_test'
require_relative 'workflows/pas_client_claim_update_cancel_request_test'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientClaimUpdatesGroup < Inferno::TestGroup
      id :pas_client_v221_claim_updates_group
      title 'Claim Updates'
      description %(
        During these tests, the client will demonstrate that it can update a previously submitted
        prior authorization request by submitting a sequence of `$submit` requests: an initial
        request, an update that adds an item, an update that modifies one item and cancels another,
        and an update that cancels the entire request.

        Inferno waits for each submission in turn, automatically continuing once it receives the
        request. Inferno never sends a Subscription notification during these interactions, even if
        the configured response indicates the request was pended.

        Once all submissions have been received, Inferno validates the conformance of each submitted
        request Bundle and of the response Bundle it returned against the PAS Request and Response
        Bundle profiles, and the verification tests check each Claim Update made during this group for
        conformance with the
        [updating authorization requests](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#updating-authorization-requests)
        requirements of the PAS IG.
      )
      run_as_group

      input :claim_update_initial_response, optional: true
      input :claim_update_add_item_response, optional: true
      input :claim_update_modify_cancel_response, optional: true
      input :claim_update_cancel_all_response, optional: true

      input_order :claim_update_initial_response,
                  :claim_update_add_item_response,
                  :claim_update_modify_cancel_response,
                  :claim_update_cancel_all_response,
                  :client_id,
                  :session_url_path

      claim_update_submit_steps = [
        { key: 'initial', title: 'Initial submission',
          submit: :pas_client_v221_claim_update_initial_submit_test, tag: CLAIM_UPDATE_INITIAL_TAG },
        { key: 'add_item', title: 'Update - add an item',
          submit: :pas_client_v221_claim_update_add_item_submit_test, tag: CLAIM_UPDATE_ADD_ITEM_TAG },
        { key: 'modify_cancel', title: 'Update - modify an item and cancel an item',
          submit: :pas_client_v221_claim_update_modify_cancel_submit_test, tag: CLAIM_UPDATE_MODIFY_CANCEL_TAG },
        { key: 'cancel_all', title: 'Update - cancel the entire request',
          submit: :pas_client_v221_claim_update_cancel_all_submit_test, tag: CLAIM_UPDATE_CANCEL_ALL_TAG }
      ]

      group do
        title 'Interaction'
        description %(
          Inferno waits for each prior authorization submission from the client in turn. Each wait test
          auto-continues when its request is received; no Subscription notifications are triggered.
        )

        claim_update_submit_steps.each { |step| test from: step[:submit] }
      end

      group do
        title 'Update Details'
        description %(
          These tests check that the sequence of requests made follow the
          update approach required.
        )

        test from: :pas_client_v221_claim_update_referenced_claim_test
        test from: :pas_client_v221_claim_update_grandparent_excluded_test
        test from: :pas_client_v221_claim_update_referenced_resources_test
        test from: :pas_client_v221_claim_update_entries_preserved_test
        test from: :pas_client_v221_claim_update_cancelled_entries_test
        test from: :pas_client_v221_claim_update_cancelled_items_certtype_test
        test from: :pas_client_v221_claim_update_changed_entries_test
        test from: :pas_client_v221_claim_update_cancel_request_test
      end

      group do
        title '$submit Conformance'
        description %(
          For each submission received above, these tests validate the conformance of the request Bundle
          the client submitted and of the response Bundle Inferno returned against the PAS Request and
          Response Bundle profiles.
        )

        claim_update_submit_steps.each do |step|
          test from: :pas_client_v221_request_bundle_validation_test do
            id :"pas_client_v221_claim_update_request_validation_#{step[:key]}"
            title "#{step[:title]}: submit request Bundle has the correct structure and content"
            config options: { workflow_tag: step[:tag] }
          end

          test from: :pas_client_v221_response_bundle_validation_test do
            id :"pas_client_v221_claim_update_response_validation_#{step[:key]}"
            title "#{step[:title]}: submit response Bundle has the correct structure and content"
            config options: { workflow_tag: step[:tag] }
          end
        end
      end
    end
  end
end
