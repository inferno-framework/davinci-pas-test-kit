require_relative '../server_request_bundle_validation_test'
require_relative '../claim_submit_operation_test'
require_relative '../server_response_bundle_validation_test'
require_relative 'claim_updates/server_claim_update_response_tests'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASServerClaimUpdatesGroup < Inferno::TestGroup
      id :pas_server_v221_claim_updates
      title 'Claim Updates'
      description %(
        Demonstrate the ability of the server to receive and respond to a sequence of Claim Update
        `$submit` requests: an initial request, an update that adds an item, an update that modifies one
        item and cancels another, and an update that cancels the entire request.

        Inferno acts as the client: for each step it validates the tester-provided request Bundle, POSTs it
        to the server's `/Claim/$submit` endpoint, and validates that the server's response Bundle is
        conformant. The tester provides the four request Bundles (the same Bundles used to drive the Client
        Suite's Claim Update tests can be reused here).

        After the sequence is sent, the verification tests reload each response and check the server's handling
        of updates against the
        [updating authorization requests](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#updating-authorization-requests)
        requirements of the PAS IG - that the returned ClaimResponse echoes submitted item sequences and
        includes current results for all submitted items, including changed or canceled items.
      )
      run_as_group

      claim_update_steps = [
        { key: 'initial', title: 'Initial submission',
          input: :claim_update_initial_submit_payload,
          input_title: 'PAS $submit Payload: Initial Claim',
          use_case: 'initial claim submission', tag: CLAIM_UPDATE_INITIAL_TAG },
        { key: 'add_item', title: 'Update: add an item',
          input: :claim_update_add_item_submit_payload,
          input_title: 'PAS $submit Payload: Update Adding an Item',
          use_case: 'add-item claim update', tag: CLAIM_UPDATE_ADD_ITEM_TAG },
        { key: 'modify_cancel', title: 'Update: modify an item and cancel an item',
          input: :claim_update_modify_cancel_submit_payload,
          input_title: 'PAS $submit Payload: Update Modifying and Canceling Items',
          use_case: 'modify-and-cancel claim update', tag: CLAIM_UPDATE_MODIFY_CANCEL_TAG },
        { key: 'cancel_all', title: 'Update: cancel the entire request',
          input: :claim_update_cancel_all_submit_payload,
          input_title: 'PAS $submit Payload: Update Canceling the Entire Request',
          use_case: 'cancel-entire-request claim update', tag: CLAIM_UPDATE_CANCEL_ALL_TAG }
      ]

      claim_update_steps.each do |step|
        group do
          title step[:title]

          test from: :pas_server_request_bundle_validation_test do
            id :"pas_server_v221_claim_update_request_validation_#{step[:key]}"
            title 'Provided $submit Request Bundle is conformant'
            description %(
              **USER INPUT VALIDATION**: This test validates input provided by the tester instead of the
              system under test. Errors encountered will be treated as a skip instead of a failure.

              This test validates the conformity of the tester-provided Claim Update request Bundle to the
              PAS Request Bundle profile so that subsequent tests can accurately exercise the server.
            )
            config(
              inputs: { bundle_payload: { name: step[:input], title: step[:input_title] } },
              options: { operation: 'submit', use_case: step[:use_case], ig_version: 'v2.2.1' }
            )
            simulation_verification
          end

          test from: :pas_claim_submit_operation_test do
            id :"pas_server_v221_claim_update_submit_#{step[:key]}"
            config(
              inputs: { pa_submit_request_payload: { name: step[:input], title: step[:input_title] } },
              options: { use_case: step[:use_case], ig_version: 'v2.2.1', request_tag: step[:tag] }
            )
          end

          test from: :pas_server_response_bundle_validation_test do
            id :"pas_server_v221_claim_update_response_validation_#{step[:key]}"
            title 'Server $submit Response Bundle is conformant'
            description %(
              This test validates the conformity of the server's response to the Claim Update `$submit`
              request against the PAS Response Bundle profile.
            )
            config(
              options: { use_case: step[:use_case], operation: 'submit', ig_version: 'v2.2.1',
                         request_tag: step[:tag] }
            )
          end
        end
      end

      group do
        title "Verify the server's responses to the claim updates"
        description %(
          These tests reload the responses the server returned during the submission sequence (by their tags)
          and verify that the server returned current results for all submitted items and echoed the submitted
          item sequences.
        )

        test from: :pas_server_v221_claim_update_item_sequence_echo_test
        test from: :pas_server_v221_claim_update_current_results_test
      end
    end
  end
end
