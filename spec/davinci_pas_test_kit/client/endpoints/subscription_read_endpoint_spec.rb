require 'udap_security_test_kit'

# Exercises Subscription read requests against the PAS client suite while a test is waiting
# on client requests. The pended submit test is used as the waiting test since it waits after a
# Subscription has been created, which is when clients are expected to read it.
RSpec.describe DaVinciPASTestKit::SubscriptionReadEndpoint, :request do
  include_context 'when testing a runnable'

  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test) { DaVinciPASTestKit::DaVinciPASV201::PASClientPendedSubmitTest }
  let(:session_url_path) { '1234' }
  let(:client_id) { 'pas-test-client' }
  let(:subscription_id) { 'pas-subscription-full-resource' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
  end
  let(:session_read_url) do
    "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}"
  end
  let(:token_read_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}" }
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

  def create_handshake_request(status:)
    notification = JSON.parse(
      File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_id_only.json'))
    )
    notification['entry'][0]['resource']['parameter']
      .find { |param| param['name'] == 'subscription' }['valueReference']['reference'] =
      "http://example.org/fhir/Subscription/#{subscription_id}"
    repo_create(
      :request,
      direction: 'outgoing',
      url: 'http://example.org/notification-endpoint',
      test_session_id: test_session.id,
      result:,
      request_body: notification.to_json,
      tags: [DaVinciPASTestKit::REST_HOOK_HANDSHAKE_NOTIFICATION_TAG],
      status:
    )
  end

  def start_waiting_test(inputs)
    create_subscription_request
    waiting_result = run(test, inputs)
    expect(waiting_result.result).to eq('wait')
    waiting_result
  end

  def get_with_token(url, token)
    get url, nil, 'HTTP_AUTHORIZATION' => "Bearer #{token}"
  end

  def response_resource
    FHIR.from_contents(last_response.body)
  end

  def read_requests
    requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::SUBSCRIPTION_READ_TAG])
  end

  describe 'when the session is identified by the URL path' do
    let!(:waiting_result) { start_waiting_test(session_url_path:) }

    it 'returns the created Subscription' do
      get session_read_url

      expect(last_response.status).to eq(200)
      expect(response_resource).to be_a(FHIR::Subscription)
      expect(response_resource.id).to eq(subscription_id)
    end

    it 'reports a requested status when no handshake has been sent' do
      get session_read_url

      expect(response_resource.status).to eq('requested')
    end

    it 'reports an active status after a successful handshake' do
      create_handshake_request(status: 200)

      get session_read_url

      expect(response_resource.status).to eq('active')
    end

    it 'reports an error status after a failed handshake' do
      create_handshake_request(status: 500)

      get session_read_url

      expect(response_resource.status).to eq('error')
    end

    it 'tags the request as a Subscription read' do
      get session_read_url

      expect(read_requests.length).to eq(1)
    end

    it 'does not complete the waiting test' do
      get session_read_url

      expect(results_repo.find(waiting_result.id).result).to eq('wait')
    end

    it 'returns a 404 OperationOutcome for an unknown Subscription id' do
      get "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/unknown-id"

      expect(last_response.status).to eq(404)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('not-found')
      expect(response_resource.issue.first.details.text).to include('unknown-id')
    end

    it 'ignores an expired bearer token since the path identifies the session' do
      get_with_token(session_read_url, expired_token)

      expect(last_response.status).to eq(200)
      expect(response_resource.id).to eq(subscription_id)
    end
  end

  describe 'when the session is identified by the bearer token' do
    before { start_waiting_test(client_id:) }

    it 'returns the created Subscription for an unexpired token' do
      get_with_token(token_read_url, valid_token)

      expect(last_response.status).to eq(200)
      expect(response_resource).to be_a(FHIR::Subscription)
      expect(response_resource.id).to eq(subscription_id)
      expect(read_requests.length).to eq(1)
    end

    it 'returns a 401 OperationOutcome for an expired token' do
      get_with_token(token_read_url, expired_token)

      expect(last_response.status).to eq(401)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('expired')
      expect(response_resource.issue.first.details.text).to eq('Bearer token has expired')
    end

    it 'does not tag a request rejected for an expired token as a Subscription read' do
      get_with_token(token_read_url, expired_token)

      expect(read_requests).to be_empty
    end

    it 'returns a 500 no-session OperationOutcome for a token issued to a different client' do
      get_with_token(token_read_url, UDAPSecurityTestKit::MockUDAPServer.client_id_to_token('other-client', 5))

      expect(last_response.status).to eq(500)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.details.text).to include('Unable to find test run')
    end

    it 'returns a 500 no-session OperationOutcome for a token that cannot be decoded' do
      get_with_token(token_read_url, 'not-a-valid-token')

      expect(last_response.status).to eq(500)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.details.text).to include('Unable to find test run')
    end
  end

  describe 'when no Subscription has been created' do
    it 'returns a 404 OperationOutcome' do
      waiting_result = run(DaVinciPASTestKit::DaVinciPASV201::PASClientApprovalSubmitTest, session_url_path:)
      expect(waiting_result.result).to eq('wait')

      get session_read_url

      expect(last_response.status).to eq(404)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('not-found')
    end
  end
end
