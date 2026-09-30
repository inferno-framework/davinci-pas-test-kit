require 'udap_security_test_kit'
require_relative '../../../../lib/davinci_pas_test_kit/client/client_urls'

# Verifies the response returned by each client suite endpoint when no waiting test
# run/session can be found for an incoming request.
RSpec.shared_examples 'a no-session OperationOutcome response' do
  it 'returns a 500 OperationOutcome' do
    post_json(request_path, {})

    expect(last_response.status).to eq(500)
    expect(last_response.headers['Content-Type']).to eq('application/fhir+json')

    outcome = FHIR.from_contents(last_response.body)
    expect(outcome).to be_a(FHIR::OperationOutcome)
    expect(outcome.issue.first.code).to eq('not-found')
    expect(outcome.issue.first.details.text).to include('Unable to find test run')
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

  describe DaVinciPASTestKit::SubscriptionStatusEndpoint do
    it_behaves_like 'a no-session OperationOutcome response' do
      let(:request_path) do
        "/custom/davinci_pas_client_suite_v201#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH}"
      end
    end
  end

  describe DaVinciPASTestKit::MockUdapSmartServer::TokenEndpoint do
    it 'returns a 401 response with an OAuth-style JSON error body' do
      post "/custom/davinci_pas_client_suite_v201#{UDAPSecurityTestKit::TOKEN_PATH}"

      expect(last_response.status).to eq(401)
      expect(last_response.headers['Content-Type']).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body['error']).to eq('invalid_client')
      expect(body['error_description']).to include('Unable to find test run')
    end
  end
end
