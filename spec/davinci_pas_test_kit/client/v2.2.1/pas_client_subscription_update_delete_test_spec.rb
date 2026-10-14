RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientSubscriptionUpdateDeleteTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:client_id) { 'pas-test-client' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
  end
  let(:subscription_id) { subscription_json['id'] }
  let(:session_instance_url) do
    "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}"
  end

  def create_subscription_request
    repo_create(
      :request,
      direction: 'incoming',
      url: "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}",
      test_session_id: test_session.id,
      result: repo_create(:result, test_session_id: test_session.id),
      response_body: subscription_json.to_json,
      tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
      status: 201
    )
  end

  def output_value(result, name)
    JSON.parse(result.output_json).find { |output| output['name'] == name.to_s }&.dig('value')
  end

  it 'skips when no Subscription was created' do
    result = run(described_class, session_url_path:)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('no Subscription exists to update or delete')
  end

  describe 'when a Subscription was created' do
    before { create_subscription_request }

    it 'waits, directing the client to the created Subscription instance' do
      result = run(described_class, session_url_path:)

      expect(result.result).to eq('wait')
      expect(result.result_message).to include("`#{subscription_id}`")
      expect(result.result_message).to include("#{session_instance_url}`")
    end

    it 'directs the client to the non-session URL when identified by client id' do
      result = run(described_class, client_id:)

      expect(result.result).to eq('wait')
      expect(result.result_message)
        .to include("/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}`")
    end

    it 'outputs the confirmation url and passes when it is followed' do
      result = run(described_class, session_url_path:)
      confirmation_url = output_value(result, :confirmation_url)

      expect(confirmation_url).to end_with("#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{session_url_path}")

      get "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{session_url_path}"

      expect(results_repo.find(result.id).result).to eq('pass')
    end

    it 'keeps waiting while the client updates and deletes the Subscription' do
      result = run(described_class, session_url_path:)

      put session_instance_url, subscription_json.merge('reason' => 'updated reason').to_json,
          'CONTENT_TYPE' => 'application/fhir+json'
      expect(last_response.status).to eq(200)
      delete session_instance_url
      expect(last_response.status).to eq(204)

      expect(results_repo.find(result.id).result).to eq('wait')
    end

    it 'waits again when re-run after an earlier run deleted the Subscription' do
      run(described_class, session_url_path:)
      delete session_instance_url
      get "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{session_url_path}"

      expect(run(described_class, session_url_path:).result).to eq('wait')
    end
  end
end
