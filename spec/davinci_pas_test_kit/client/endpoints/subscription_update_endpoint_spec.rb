require 'udap_security_test_kit'

# Exercises Subscription update requests against the PAS client suite. The base update behavior is
# covered by the subscriptions test kit, so these focus on how the PAS suite identifies the session and
# when it accepts updates.
RSpec.describe DaVinciPASTestKit::SubscriptionUpdateEndpoint, :request do
  include_context 'when testing a runnable'

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:update_delete_test) { DaVinciPASTestKit::DaVinciPASV221::PASClientSubscriptionUpdateDeleteTest }
  let(:session_url_path) { '1234' }
  let(:client_id) { 'pas-test-client' }
  let(:subscription_id) { 'pas-subscription-full-resource' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
  end
  let(:updated_subscription_json) { subscription_json.merge('reason' => 'updated reason') }
  let(:session_instance_url) do
    "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}"
  end
  let(:token_instance_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}" }
  let(:valid_token) { UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5) }
  let(:expired_token) { UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -5) }

  def create_subscription_request
    repo_create(
      :request,
      direction: 'incoming',
      url: "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}",
      test_session_id: test_session.id,
      result:,
      response_body: subscription_json.to_json,
      tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
      status: 201
    )
  end

  def start_waiting_test(inputs, waiting_test = update_delete_test)
    create_subscription_request
    waiting_result = run(waiting_test, inputs)
    expect(waiting_result.result).to eq('wait')
    waiting_result
  end

  def put_subscription(url, subscription, token: nil)
    headers = { 'CONTENT_TYPE' => 'application/fhir+json' }
    headers['HTTP_AUTHORIZATION'] = "Bearer #{token}" if token.present?
    put url, subscription.to_json, headers
  end

  def response_resource
    FHIR.from_contents(last_response.body)
  end

  def update_requests
    requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::SUBSCRIPTION_UPDATE_TAG, subscription_id])
  end

  describe 'when the session is identified by the URL path' do
    let!(:waiting_result) { start_waiting_test(session_url_path:) }

    it 'returns the updated Subscription' do
      put_subscription(session_instance_url, updated_subscription_json)

      expect(last_response.status).to eq(200)
      expect(response_resource).to be_a(FHIR::Subscription)
      expect(response_resource.id).to eq(subscription_id)
      expect(response_resource.reason).to eq('updated reason')
    end

    it 'returns the updated Subscription on a later read' do
      put_subscription(session_instance_url, updated_subscription_json)

      get session_instance_url

      expect(last_response.status).to eq(200)
      expect(response_resource.reason).to eq('updated reason')
    end

    it 'tags the request as an update of the Subscription' do
      put_subscription(session_instance_url, updated_subscription_json)

      expect(update_requests.length).to eq(1)
    end

    it 'does not complete the waiting test' do
      put_subscription(session_instance_url, updated_subscription_json)

      expect(results_repo.find(waiting_result.id).result).to eq('wait')
    end

    it 'returns a 404 OperationOutcome for an unknown Subscription id' do
      put_subscription("/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/unknown-id",
                       updated_subscription_json.merge('id' => 'unknown-id'))

      expect(last_response.status).to eq(404)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('not-found')
    end

    it 'ignores an expired bearer token since the path identifies the session' do
      put_subscription(session_instance_url, updated_subscription_json, token: expired_token)

      expect(last_response.status).to eq(200)
      expect(response_resource.reason).to eq('updated reason')
    end
  end

  describe 'when the session is identified by the bearer token' do
    before { start_waiting_test(client_id:) }

    it 'returns the updated Subscription for an unexpired token' do
      put_subscription(token_instance_url, updated_subscription_json, token: valid_token)

      expect(last_response.status).to eq(200)
      expect(response_resource.reason).to eq('updated reason')
      expect(update_requests.length).to eq(1)
    end

    it 'returns a 401 OperationOutcome for an expired token' do
      put_subscription(token_instance_url, updated_subscription_json, token: expired_token)

      expect(last_response.status).to eq(401)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('expired')
      expect(response_resource.issue.first.details.text).to eq('Bearer token has expired')
    end

    it 'does not tag a request rejected for an expired token as an update' do
      put_subscription(token_instance_url, updated_subscription_json, token: expired_token)

      expect(update_requests).to be_empty
    end

    it 'returns a 500 no-session OperationOutcome for a token issued to a different client' do
      put_subscription(token_instance_url, updated_subscription_json,
                       token: UDAPSecurityTestKit::MockUDAPServer.client_id_to_token('other-client', 5))

      expect(last_response.status).to eq(500)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.details.text).to include('Unable to find test run')
    end
  end

  describe 'when a different test is waiting' do
    before do
      start_waiting_test({ session_url_path: }, DaVinciPASTestKit::DaVinciPASV221::PASClientApprovalSubmitTest)
    end

    it 'rejects the update with a 422 OperationOutcome' do
      put_subscription(session_instance_url, updated_subscription_json)

      expect(last_response.status).to eq(422)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('business-rule')
    end

    it 'does not tag the rejected request as an update' do
      put_subscription(session_instance_url, updated_subscription_json)

      expect(update_requests).to be_empty
    end
  end
end
