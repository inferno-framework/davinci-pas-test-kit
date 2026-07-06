# Behavioral specs for the server-side Claim Update response verification tests (ID-56). Inferno sends
# update submissions to the server under test; these tests reload each submission by its tag and compare
# the submitted Claim's item sequences against the ClaimResponse the server returned (spec-34 echo and
# spec-46 current-results-for-all-items). Both are pure structural checks (no FHIR validator).
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::ServerClaimUpdateResponseValidation, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }

  def claim_bundle(*sequences)
    {
      resourceType: 'Bundle', type: 'collection',
      entry: [{
        resource: {
          resourceType: 'Claim', id: 'claim-update', status: 'active', use: 'preauthorization',
          item: sequences.map { |seq| { sequence: seq, productOrService: { text: "service-#{seq}" } } }
        }
      }]
    }.to_json
  end

  def claim_response_bundle(*item_sequences)
    {
      resourceType: 'Bundle', type: 'collection',
      entry: [{
        resource: {
          resourceType: 'ClaimResponse', id: 'claim-response', status: 'active', use: 'preauthorization',
          outcome: 'complete',
          item: item_sequences.map { |seq| { itemSequence: seq } }
        }
      }]
    }.to_json
  end

  # A conformant update Bundle: the update Claim is the first entry and the referenced prior Claim
  # (with different items) is also included, per spec-65.
  def update_bundle_with_prior(update_sequences, prior_sequences)
    {
      resourceType: 'Bundle', type: 'collection',
      entry: [
        {
          fullUrl: 'urn:uuid:update',
          resource: {
            resourceType: 'Claim', id: 'update', status: 'active', use: 'preauthorization',
            related: [{ claim: { reference: 'urn:uuid:prior' } }],
            item: update_sequences.map { |seq| { sequence: seq, productOrService: { text: "service-#{seq}" } } }
          }
        },
        {
          fullUrl: 'urn:uuid:prior',
          resource: {
            resourceType: 'Claim', id: 'prior', status: 'active', use: 'preauthorization',
            item: prior_sequences.map { |seq| { sequence: seq, productOrService: { text: "service-#{seq}" } } }
          }
        }
      ]
    }.to_json
  end

  def seed_step(tag, request_body, response_body)
    repo_create(
      :request,
      direction: 'outgoing',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body:,
      response_body:,
      tags: [tag, DaVinciPASTestKit::SUBMIT_TAG],
      status: 200
    )
  end

  # A fully conformant sequence: each update's response echoes and covers exactly the submitted items.
  def seed_conformant_sequence
    seed_step(DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG, claim_bundle(1), claim_response_bundle(1))
    seed_step(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, claim_bundle(1, 2), claim_response_bundle(1, 2))
    seed_step(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG, claim_bundle(1, 2), claim_response_bundle(1, 2))
    # cancel-entire-request: no items submitted, so it is excluded from the item-sequence checks
    seed_step(DaVinciPASTestKit::CLAIM_UPDATE_CANCEL_ALL_TAG, claim_bundle, claim_response_bundle)
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASServerClaimUpdateItemSequenceEchoTest do # spec-34
    it 'skips when the server returned no Claim Update responses with items' do
      seed_step(DaVinciPASTestKit::CLAIM_UPDATE_CANCEL_ALL_TAG, claim_bundle, claim_response_bundle)
      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when every returned item echoes a submitted item.sequence' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when the response returns an item.itemSequence that was not submitted' do
      seed_step(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                claim_bundle(1, 2), claim_response_bundle(1, 2, 99))
      expect(run(described_class).result).to eq('fail')
    end

    it 'compares against the update Claim (first entry), not the included prior Claim' do
      # Update Claim has items 1,2; the included prior Claim has only item 1. The server echoes 1,2.
      # If the prior Claim were used as the submitted Claim, item 2 would look unexpected and fail.
      seed_step(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                update_bundle_with_prior([1, 2], [1]), claim_response_bundle(1, 2))
      expect(run(described_class).result).to eq('pass')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASServerClaimUpdateCurrentResultsTest do # spec-46
    it 'skips when the server returned no Claim Update responses with items' do
      seed_step(DaVinciPASTestKit::CLAIM_UPDATE_CANCEL_ALL_TAG, claim_bundle, claim_response_bundle)
      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when the response includes results for all submitted items (incl. canceled)' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when the response omits a submitted item (e.g. a canceled item)' do
      # Submitted items 1 and 2 (2 canceled) but the server only returned a result for item 1.
      seed_step(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                claim_bundle(1, 2), claim_response_bundle(1))
      expect(run(described_class).result).to eq('fail')
    end
  end
end
