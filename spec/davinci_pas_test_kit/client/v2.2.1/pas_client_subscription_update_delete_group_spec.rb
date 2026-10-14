# Runs the conformance tests of the Subscription Update and Deletion group, including those reused from the
# subscriptions test kit, against update and delete requests sent to the PAS client suite's endpoints. This
# checks that the reused tests find the Subscription created and the requests tagged by the PAS suite.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientUpdateDeleteWorkflowGroup, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_v221_good.json')))
  end
  let(:subscription_id) { subscription_json['id'] }
  let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
  let(:subscription_instance_url) { "#{subscription_url}/#{subscription_id}" }
  let(:resume_pass_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{session_url_path}" }
  let(:conformance_group) { find_test(suite, 'pas_client_v221_subscription_update_delete_conformance') }
  let(:validation_success) { { outcomes: [{ issues: [] }], sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2' } }

  before do
    stub_request(:post, validation_url).to_return(status: 200, body: validation_success.to_json)
    repo_create(:request, verb: 'POST', direction: 'incoming', url: subscription_url, test_session_id: test_session.id,
                          result: repo_create(:result, test_session_id: test_session.id),
                          request_body: subscription_json.except('id').to_json,
                          response_body: subscription_json.to_json,
                          tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], status: 201)
  end

  it 'passes the conformance tests for update and delete requests made to the PAS endpoints' do
    run(DaVinciPASTestKit::DaVinciPASV221::PASClientSubscriptionUpdateDeleteTest, session_url_path:)
    put subscription_instance_url, subscription_json.merge('reason' => 'updated reason').to_json,
        'CONTENT_TYPE' => 'application/fhir+json'
    expect(last_response.status).to eq(200)
    delete subscription_instance_url
    expect(last_response.status).to eq(204)
    get resume_pass_url

    results = conformance_group.tests.to_h { |test| [test.id.split('-').last, run(test).result] }

    expect(results).to eq(
      'subscriptions_r4_client_put_update_verification' => 'pass',
      'pas_client_v221_subscription_put_update_pas_conformance_test' => 'pass',
      'subscriptions_r4_client_delete_verification' => 'pass'
    )
  end
end
