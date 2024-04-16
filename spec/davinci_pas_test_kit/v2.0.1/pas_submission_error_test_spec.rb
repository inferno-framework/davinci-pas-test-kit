RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PasSubmissionErrorTest do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('davinci_pas_server_suite_v201') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:test) do
    Class.new(DaVinciPASTestKit::DaVinciPASV201::PasSubmissionErrorTest) do
      fhir_client { url :server_endpoint }
      input :server_endpoint
    end
  end
  let(:error_outcome) { FHIR::OperationOutcome.new(issue: [{ severity: 'error' }]) }
  let(:pa_request_payload) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'nonconformant_pas_bundle_v110.json'))
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  it 'passes if the HTTP status is not within 2xx range' do
    stub_request(:post, "#{server_endpoint}/Claim/$submit")
      .with(
        body: JSON.parse(pa_request_payload)
      )
      .to_return(status: 400, body: error_outcome.to_json)

    result = run(test, server_endpoint:)
    expect(result.result).to eq('pass')
  end

  it 'fails if the HTTP status is within 2xx range' do
    stub_request(:post, "#{server_endpoint}/Claim/$submit")
      .with(
        body: JSON.parse(pa_request_payload)
      )
      .to_return(status: 200, body: {}.to_json)

    result = run(test, server_endpoint:)
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/HTTP status code should not be within the 2xx range/)
  end
end
