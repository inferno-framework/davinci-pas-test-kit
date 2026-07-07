# Behavioral specs for the PAS v2.2.1 Claim Update wait tests (ID-56). Confirms that a wait test
# auto-continues on receipt of a submission, tags the received request with its unique tag, and never
# triggers a Subscription notification - even when the configured response indicates the request was pended.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateInitialSubmitTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { 'claim-update-session' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }

  let(:claim_full_url) { 'urn:uuid:aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' }
  let(:submit_bundle) do
    {
      resourceType: 'Bundle',
      type: 'collection',
      entry: [
        {
          fullUrl: claim_full_url,
          resource: { resourceType: 'Claim', id: 'claim-1', status: 'active', use: 'preauthorization',
                      item: [{ sequence: 1, productOrService: { text: 'service-1' } }] }
        }
      ]
    }.to_json
  end

  # A pended response body - used to prove a pended response still does not trigger a notification.
  let(:pended_response) do
    {
      resourceType: 'Bundle',
      type: 'collection',
      entry: [
        { resource: { resourceType: 'ClaimResponse', id: 'cr-1', status: 'active', use: 'preauthorization',
                      outcome: 'queued', created: '2024-01-01T00:00:00Z' } }
      ]
    }.to_json
  end

  it 'waits for a submission from the client' do
    result = run(described_class, session_url_path:)
    expect(result.result).to eq('wait')
  end

  it 'auto-continues (passes) when a submission is received' do
    result = run(described_class, session_url_path:)
    expect(result.result).to eq('wait')

    post_json(submit_url, JSON.parse(submit_bundle))

    expect(results_repo.find(result.id).result).to eq('pass')
  end

  it 'tags the received request with its unique claim update tag' do
    run(described_class, session_url_path:)
    post_json(submit_url, JSON.parse(submit_bundle))

    tagged = requests_repo.tagged_requests(test_session.id,
                                           [DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG,
                                            DaVinciPASTestKit::SUBMIT_TAG])
    expect(tagged.length).to eq(1)
  end

  it 'does not trigger a subscription notification even when the response is pended' do
    run(described_class, session_url_path:, claim_update_initial_response: pended_response)

    # The wait auto-resume (ResumeTestRun) job is expected; the subscription notification job is not.
    allow(Inferno::Jobs).to receive(:perform).and_call_original
    post_json(submit_url, JSON.parse(submit_bundle))

    expect(Inferno::Jobs).to_not have_received(:perform)
      .with(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification, any_args)
  end
end
