# Covers when the pended $submit test can start waiting. Responding to $submit requests is covered for
# v2.0.1 in its pended submit test spec.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientPendedSubmitTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
  end
  let(:subscription_id) { subscription_json['id'] }

  def create_request(tags:, status:, response_body: nil)
    repo_create(:request, direction: 'incoming', url: subscription_url, test_session_id: test_session.id, result:,
                          status:, response_body:, tags:)
  end

  def create_subscription_request
    create_request(tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], status: 201,
                   response_body: subscription_json.to_json)
  end

  it 'skips when there is no Subscription' do
    result = run(described_class, session_url_path:)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('no Subscription exists to receive notifications')
  end

  describe 'when a Subscription was created' do
    before { create_subscription_request }

    it 'waits when the Subscription has not been changed' do
      expect(run(described_class, session_url_path:).result).to eq('wait')
    end

    it 'skips when the client has updated the Subscription' do
      create_request(tags: [SubscriptionsTestKit::SUBSCRIPTION_UPDATE_TAG, subscription_id], status: 200,
                     response_body: subscription_json.to_json)
      result = run(described_class, session_url_path:)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('submitted update or delete requests')
    end

    it 'skips when the client has deleted the Subscription' do
      create_request(tags: [SubscriptionsTestKit::SUBSCRIPTION_DELETE_TAG, subscription_id], status: 204)
      result = run(described_class, session_url_path:)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('submitted update or delete requests')
    end

    it 'waits when the client\'s update and delete requests were rejected' do
      create_request(tags: [SubscriptionsTestKit::SUBSCRIPTION_UPDATE_TAG, subscription_id], status: 400)
      create_request(tags: [SubscriptionsTestKit::SUBSCRIPTION_DELETE_TAG, subscription_id], status: 404)

      expect(run(described_class, session_url_path:).result).to eq('wait')
    end
  end
end
