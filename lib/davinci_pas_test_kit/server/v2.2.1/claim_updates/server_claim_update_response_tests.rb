require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Shared helpers for the server-side Claim Update response verification tests. Inferno (acting
    # as the client) sends a sequence of update submissions to the server under test; these helpers
    # reload each submission by its unique tag and compare the submitted Claim's items against the
    # ClaimResponse the server returned. No live state is used - everything is reloaded from the
    # tagged, persisted requests/responses.
    module ServerClaimUpdateResponseValidation
      # The ordered Claim Update submissions, paired with the unique tag each was stored under.
      def claim_update_response_steps
        [
          { label: 'initial submission', tag: CLAIM_UPDATE_INITIAL_TAG },
          { label: 'add-item update', tag: CLAIM_UPDATE_ADD_ITEM_TAG },
          { label: 'modify-and-cancel update', tag: CLAIM_UPDATE_MODIFY_CANCEL_TAG },
          { label: 'cancel-entire-request update', tag: CLAIM_UPDATE_CANCEL_ALL_TAG }
        ]
      end

      # The most recent request stored under `tag` (it carries both the request body Inferno sent
      # and the response body the server returned).
      def tagged_update_request(tag)
        load_tagged_requests(tag).last
      end

      # The Claim under submission is the first Bundle entry (a conformant update Bundle also
      # includes the referenced prior Claim per spec-65, so select by position, not by type-order).
      def submitted_claim(request)
        first_resource_of_type(request&.request_body, FHIR::Claim)
      end

      # The PAS Response Bundle starts with the ClaimResponse.
      def response_claim_response(request)
        first_resource_of_type(request&.response_body, FHIR::ClaimResponse)
      end

      def first_resource_of_type(body, type)
        return nil if body.blank?

        bundle = FHIR.from_contents(body)
        return nil unless bundle.is_a?(FHIR::Bundle)

        first_resource = bundle.entry.first&.resource
        return first_resource if first_resource.is_a?(type)

        # Fall back to the first matching resource if the Bundle is ordered unexpectedly.
        bundle.entry.map(&:resource).find { |resource| resource.is_a?(type) }
      rescue StandardError
        nil
      end

      def claim_item_sequences(claim)
        Array(claim&.item).map(&:sequence).compact
      end

      def claim_response_item_sequences(claim_response)
        Array(claim_response&.item).map(&:itemSequence).compact
      end

      # Collects the steps for which the server returned a ClaimResponse, attaching the submitted
      # Claim item sequences and the returned ClaimResponse item sequences.
      def evaluated_update_steps
        claim_update_response_steps.filter_map do |step|
          request = tagged_update_request(step[:tag])
          next if request.nil?

          claim = submitted_claim(request)
          claim_response = response_claim_response(request)
          next if claim.nil? || claim_response.nil?

          step.merge(submitted_sequences: claim_item_sequences(claim),
                     response_sequences: claim_response_item_sequences(claim_response))
        end
      end

      # The item-bearing steps (cancel-entire-request carries no items, so item.sequence checks do
      # not apply to it).
      def item_bearing_update_steps
        evaluated_update_steps.reject { |step| step[:submitted_sequences].empty? }
      end
    end

    # spec-34
    class PASServerClaimUpdateItemSequenceEchoTest < Inferno::Test
      include ServerClaimUpdateResponseValidation

      id :pas_server_v221_claim_update_item_sequence_echo_test
      title 'Server echoes item.sequence values in Claim Update responses (spec-34)'
      description %(
        Verifies [spec-34](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-34):
        each item returned on the PAS ClaimResponse **SHALL** echo the same `item.sequence` as that same item had
        on the Claim. This test reloads each Claim Update submission sent to the server (by its tag) and confirms
        that every `ClaimResponse.item.itemSequence` in the server's response corresponds to an `item.sequence`
        that was present on the submitted Claim.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-34'

      run do
        steps = item_bearing_update_steps
        skip_if steps.empty?,
                'No Claim Update responses with items were returned by the server to verify.'

        steps.each do |step|
          unexpected = step[:response_sequences] - step[:submitted_sequences]
          assert unexpected.empty?,
                 "In the server's response to the #{step[:label]}, the ClaimResponse returned " \
                 "item.itemSequence value(s) #{unexpected.join(', ')} that were not present on the submitted " \
                 'Claim. Each returned item SHALL echo an item.sequence from the submitted Claim.'
        end

        pass 'Every ClaimResponse item echoes an item.sequence from the submitted Claim Update.'
      end
    end

    # spec-46
    class PASServerClaimUpdateCurrentResultsTest < Inferno::Test
      include ServerClaimUpdateResponseValidation

      id :pas_server_v221_claim_update_current_results_test
      title 'Server returns current results for all submitted items in Claim Update responses (spec-46)'
      description %(
        Verifies [spec-46](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-46):
        the returned ClaimResponse **SHALL** include the current results for all submitted items, including any
        items changed or canceled since the original authorization request. Because a conformant Claim Update
        carries all items from the original and prior updates (spec-68), this test reloads each Claim Update
        submission sent to the server (by its tag) and confirms the server's ClaimResponse includes an
        `item.itemSequence` for every `item.sequence` on the submitted Claim.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-46'

      run do
        steps = item_bearing_update_steps
        skip_if steps.empty?,
                'No Claim Update responses with items were returned by the server to verify.'

        steps.each do |step|
          missing = step[:submitted_sequences] - step[:response_sequences]
          assert missing.empty?,
                 "The server's response to the #{step[:label]} did not include results for all submitted items. " \
                 "Missing ClaimResponse item.itemSequence value(s): #{missing.join(', ')}. The returned " \
                 'ClaimResponse SHALL include the current results for all submitted items, including changed or ' \
                 'canceled items.'
        end

        pass "The server's Claim Update responses include current results for all submitted items."
      end
    end
  end
end
