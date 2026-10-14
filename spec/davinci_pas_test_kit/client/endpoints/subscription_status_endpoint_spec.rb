require 'udap_security_test_kit'

# Exercises Subscription $status requests against the PAS client suite, focusing on how the reported
# status reflects updates and deletion of the Subscription by the client. The update and delete test is
# used as the waiting test since it is when the client is able to change the Subscription.
RSpec.describe DaVinciPASTestKit::SubscriptionStatusEndpoint, :request do
  include_context 'when testing a runnable'

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:test) { DaVinciPASTestKit::DaVinciPASV221::PASClientSubscriptionUpdateDeleteTest }
  let(:session_url_path) { '1234' }
  let(:client_id) { 'pas-test-client' }
  let(:wait_inputs) { { session_url_path: } }
  let(:subscription_id) { 'pas-subscription-full-resource' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
  end
  let(:subscription_url) do
    "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}"
  end
  let(:instance_status_url) { "#{subscription_url}/#{subscription_id}/$status" }
  let(:resource_status_url) { "#{subscription_url}/$status" }
  let(:token_instance_status_url) do
    "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/#{subscription_id}/$status"
  end
  let(:requests_repo) { Inferno::Repositories::Requests.new }

  def create_request(tags:, status:, response_body:, direction: 'incoming', request_body: nil)
    repo_create(:request, direction:, url: subscription_url, test_session_id: test_session.id, result:,
                          status:, request_body:, response_body:, tags:)
  end

  def create_handshake_request
    notification = JSON.parse(
      File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_id_only.json'))
    )
    notification['entry'][0]['resource']['parameter']
      .find { |param| param['name'] == 'subscription' }['valueReference']['reference'] =
      "http://example.org/fhir/Subscription/#{subscription_id}"
    create_request(tags: [DaVinciPASTestKit::REST_HOOK_HANDSHAKE_NOTIFICATION_TAG], status: 200,
                   direction: 'outgoing', request_body: notification.to_json, response_body: nil)
  end

  def create_update_request(status:, subscription_status:)
    updated_subscription = subscription_json.merge('status' => subscription_status)
    create_request(tags: [DaVinciPASTestKit::SUBSCRIPTION_UPDATE_TAG, subscription_id], status:,
                   response_body: updated_subscription.to_json)
  end

  def create_delete_request(status:)
    create_request(tags: [DaVinciPASTestKit::SUBSCRIPTION_DELETE_TAG, subscription_id], status:,
                   response_body: nil)
  end

  def reported_status
    status_parameters = FHIR.from_contents(last_response.body).entry.first.resource
    status_parameters.parameter.find { |param| param.name == 'status' }.value
  end

  def post_status_parameters(status)
    params = FHIR::Parameters.new(parameter: [{ name: 'status', valueString: status }])
    post resource_status_url, params.to_json, 'CONTENT_TYPE' => 'application/fhir+json'
  end

  before do
    create_request(tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], status: 201,
                   response_body: subscription_json.to_json)
    create_handshake_request
    run(test, wait_inputs)
  end

  it 'reports an active status for the Subscription as created' do
    get instance_status_url

    expect(last_response.status).to eq(200)
    expect(reported_status).to eq('active')
  end

  it 'ignores an expired bearer token since the path identifies the session' do
    get instance_status_url, nil,
        'HTTP_AUTHORIZATION' => "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -5)}"

    expect(last_response.status).to eq(200)
    expect(reported_status).to eq('active')
  end

  it 'returns a 404 for a different Subscription id' do
    get "#{subscription_url}/unknown-id/$status"

    expect(last_response.status).to eq(404)
  end

  it 'returns a 404 once the Subscription has been deleted' do
    create_delete_request(status: 204)

    get instance_status_url

    expect(last_response.status).to eq(404)
  end

  it 'ignores a rejected delete' do
    create_delete_request(status: 422)

    get instance_status_url

    expect(last_response.status).to eq(200)
    expect(reported_status).to eq('active')
  end

  it 'reports an off status once the Subscription has been updated to off' do
    create_update_request(status: 200, subscription_status: 'off')

    get instance_status_url

    expect(last_response.status).to eq(200)
    expect(reported_status).to eq('off')
  end

  it 'ignores a rejected update to off' do
    create_update_request(status: 400, subscription_status: 'off')

    get instance_status_url

    expect(reported_status).to eq('active')
  end

  it 'reflects update and delete requests sent to the PAS Subscription endpoints' do
    put "#{subscription_url}/#{subscription_id}", subscription_json.merge('status' => 'off').to_json,
        'CONTENT_TYPE' => 'application/fhir+json'
    expect(last_response.status).to eq(200)

    get instance_status_url
    expect(last_response.status).to eq(200)
    expect(reported_status).to eq('off')

    delete "#{subscription_url}/#{subscription_id}"
    expect(last_response.status).to eq(204)

    get instance_status_url
    expect(last_response.status).to eq(404)
  end

  it 'matches resource-level status parameters against the updated status' do
    create_update_request(status: 200, subscription_status: 'off')

    post_status_parameters('active')
    expect(last_response.status).to eq(404)

    post_status_parameters('off')
    expect(last_response.status).to eq(200)
    expect(reported_status).to eq('off')
  end

  describe 'when the session is identified by the bearer token' do
    let(:wait_inputs) { { client_id: } }

    def get_with_token(token)
      get token_instance_status_url, nil, 'HTTP_AUTHORIZATION' => "Bearer #{token}"
    end

    def status_requests
      requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::SUBSCRIPTION_STATUS_TAG])
    end

    it 'reports the status for an unexpired token' do
      get_with_token(UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5))

      expect(last_response.status).to eq(200)
      expect(reported_status).to eq('active')
      expect(status_requests.length).to eq(1)
    end

    it 'returns a 401 OperationOutcome and does not tag the request for an expired token' do
      get_with_token(UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -5))

      expect(last_response.status).to eq(401)
      response_resource = FHIR.from_contents(last_response.body)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('expired')
      expect(status_requests).to be_empty
    end
  end
end
