require_relative 'workflows/pas_client_claim_update_submit_tests'
require_relative 'workflows/pas_client_claim_update_verification_tests'
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

        Once all submissions have been received, the verification tests reload each request by its tag
        and check the conformance of the submitted PAS Claim Update Bundles against the
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

      group do
        title 'Submit the claim update sequence'
        description %(
          Inferno waits for each prior authorization submission from the client in turn. Each wait test
          auto-continues when its request is received; no Subscription notifications are triggered.
        )

        test from: :pas_client_v221_claim_update_initial_submit_test
        test from: :pas_client_v221_claim_update_add_item_submit_test
        test from: :pas_client_v221_claim_update_modify_cancel_submit_test
        test from: :pas_client_v221_claim_update_cancel_all_submit_test
      end

      group do
        title 'Verify the claim update interactions'
        description %(
          These tests reload the requests received during the submission sequence (by their tags) and
          verify the conformance of the submitted PAS Claim Update Bundles.
        )

        test from: :pas_client_v221_claim_update_referenced_claim_test
        test from: :pas_client_v221_claim_update_grandparent_excluded_test
        test from: :pas_client_v221_claim_update_referenced_resources_test
        test from: :pas_client_v221_claim_update_entries_preserved_test
        test from: :pas_client_v221_claim_update_cancelled_entries_test
        test from: :pas_client_v221_claim_update_cancelled_items_certtype_test
        test from: :pas_client_v221_claim_update_changed_entries_test
        test from: :pas_client_v221_claim_update_info_changed_code_test
      end
    end
  end
end
