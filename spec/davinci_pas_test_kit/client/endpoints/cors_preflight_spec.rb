# Exercises the CORS preflight responses that allow_cors adds to the PAS client suite routes.
RSpec.describe 'PAS client suite CORS preflight', :request do # rubocop:disable RSpec/DescribeClass
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:subscription_instance_url) do
    "/custom/#{suite_id}/1234#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}/pas-subscription-full-resource"
  end

  it 'allows the methods used for Subscription update and delete' do
    options(subscription_instance_url)

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    expect(last_response.headers['Access-Control-Allow-Methods'].split(', ')).to include('PUT', 'DELETE')
    expect(last_response.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Authorization')
  end
end
