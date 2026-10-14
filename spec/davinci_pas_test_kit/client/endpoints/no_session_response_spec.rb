require 'udap_security_test_kit'
require_relative '../../../../lib/davinci_pas_test_kit/client/client_urls'

# Verifies the response returned by each client suite endpoint when no waiting test
# run/session can be found for an incoming request.
RSpec.shared_examples 'a no-session OperationOutcome response' do |http_method = :post|
  it 'returns a 500 OperationOutcome' do
    http_method == :post ? post_json(request_path, {}) : send(http_method, request_path)

    expect(last_response.status).to eq(500)
    expect(last_response.headers['Content-Type']).to eq('application/fhir+json')

    outcome = FHIR.from_contents(last_response.body)
    expect(outcome).to be_a(FHIR::OperationOutcome)
    expect(outcome.issue.first.code).to eq('not-found')
    expect(outcome.issue.first.details.text).to include('Unable to find test run')
    expect(outcome.issue.first.details.text).to include(DaVinciPASTestKit::SessionIdentification::LOCATION_DESCRIPTION)
  end
end

RSpec.describe DaVinciPASTestKit::ClaimEndpoint, :request do
  it_behaves_like 'a no-session OperationOutcome response' do
    let(:request_path) { "/custom/davinci_pas_client_suite_v201#{DaVinciPASTestKit::SUBMIT_PATH}" }
  end

  describe DaVinciPASTestKit::SubscriptionCreateEndpoint do
    it_behaves_like 'a no-session OperationOutcome response' do
      let(:request_path) { "/custom/davinci_pas_client_suite_v201#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    end
  end

  describe DaVinciPASTestKit::SubscriptionReadEndpoint do
    it_behaves_like 'a no-session OperationOutcome response', :get do
      let(:request_path) { "/custom/davinci_pas_client_suite_v201#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/abc" }
    end
  end

  # Update and delete are only supported by the v2.2.1 client suite
  describe DaVinciPASTestKit::SubscriptionUpdateEndpoint do
    it_behaves_like 'a no-session OperationOutcome response', :put do
      let(:request_path) { "/custom/davinci_pas_client_suite_v221#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/abc" }
    end
  end

  describe DaVinciPASTestKit::SubscriptionDeleteEndpoint do
    it_behaves_like 'a no-session OperationOutcome response', :delete do
      let(:request_path) { "/custom/davinci_pas_client_suite_v221#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/abc" }
    end
  end

  describe DaVinciPASTestKit::SubscriptionStatusEndpoint do
    it_behaves_like 'a no-session OperationOutcome response' do
      let(:request_path) do
        "/custom/davinci_pas_client_suite_v201#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH}"
      end
    end
  end

  describe DaVinciPASTestKit::MockUdapSmartServer::TokenEndpoint do
    let(:token_path) { "/custom/davinci_pas_client_suite_v201#{UDAPSecurityTestKit::TOKEN_PATH}" }

    def expect_invalid_client_response
      expect(last_response.status).to eq(401)
      expect(last_response.headers['Content-Type']).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('invalid_client')
      expect(body['error_description']).to include('Unable to find test run')
    end

    it 'returns a 401 response with an OAuth-style JSON error body' do
      post token_path

      expect_invalid_client_response
    end

    it 'returns a 401 response when the client assertion is not a valid JWT' do
      post token_path, { client_assertion: 'not-a-jwt' }

      expect_invalid_client_response
    end

    it 'returns a 401 response when the client assertion identifies a client with no waiting test run' do
      client_assertion = JWT.encode({ iss: 'unknown-client-id' }, nil, 'none')
      post token_path, { client_assertion: }

      expect_invalid_client_response
    end

    context 'when a test run is waiting for a different client' do
      include_context 'when testing a runnable'

      let(:suite_id) { 'davinci_pas_client_suite_v201' }

      it "returns a 401 response when the client assertion's iss does not match the waiting client id" do
        waiting_result = run(DaVinciPASTestKit::DaVinciPASV201::PASClientApprovalSubmitTest,
                             client_id: 'waiting-client-id')
        expect(waiting_result.result).to eq('wait')

        client_assertion = JWT.encode({ iss: 'other-client-id' }, nil, 'none')
        post token_path, { client_assertion: }

        expect_invalid_client_response
      end
    end
  end
end
