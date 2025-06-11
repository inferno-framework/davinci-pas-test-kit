RSpec.describe DaVinciPASTestKit::DaVinciPASV201::ClaimOperationTest do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:server_endpoint) { 'http://example.com/fhir' }

  let(:test) do
    Class.new(DaVinciPASTestKit::DaVinciPASV201::ClaimOperationTest) do
      fhir_client { url :server_endpoint }
      input :server_endpoint
    end
  end

  let(:pa_submit_request_payload) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  it 'passes if the PA response has a 200 status for Claim/$submit operation' do
    stub_request(:post, "#{server_endpoint}/Claim/$submit")
      .with(
        body: JSON.parse(pa_submit_request_payload)
      )
      .to_return(status: 200, body: {}.to_json)

    result = run(test, pa_submit_request_payload:, server_endpoint:)
    expect(result.result).to eq('pass')
  end

  it 'fails if the PA response has a status other than 200 or 201 for Claim/$submit operation' do
    stub_request(:post, "#{server_endpoint}/Claim/$submit")
      .with(
        body: JSON.parse(pa_submit_request_payload)
      )
      .to_return(status: 400, body: {}.to_json)

    result = run(test, pa_submit_request_payload:, server_endpoint:)
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Unexpected response status/)
  end
end
