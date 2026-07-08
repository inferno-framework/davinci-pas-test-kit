require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/urls'
require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/error_handling/' \
                 'pas_client_operation_failure_submit_test'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientOperationFailureSubmitTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:submit_request_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:operation_outcome_json) do
    JSON.generate(
      resourceType: 'OperationOutcome',
      issue: [{ severity: 'error', code: 'invalid',
                details: { text: 'The submitted Bundle could not be processed.' } }]
    )
  end

  describe 'when the tester provides a valid OperationOutcome input' do
    it 'passes when a submit request is received' do
      inputs = { session_url_path:, operation_failure_operation_outcome: operation_outcome_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'returns HTTP status 400 by default' do
      inputs = { session_url_path:, operation_failure_operation_outcome: operation_outcome_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(400)
    end

    it 'returns the configured HTTP status when operation_failure_http_status is set' do
      inputs = {
        session_url_path:,
        operation_failure_operation_outcome: operation_outcome_json,
        operation_failure_http_status: '422'
      }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(422)
    end

    it 'returns the OperationOutcome body' do
      inputs = { session_url_path:, operation_failure_operation_outcome: operation_outcome_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      fhir_body = FHIR.from_contents(last_response.body)
      expect(fhir_body).to be_a(FHIR::OperationOutcome)
    end

    it 'tags submit requests with OPERATION_FAILURE_WORKFLOW_TAG and SUBMIT_TAG' do
      inputs = { session_url_path:, operation_failure_operation_outcome: operation_outcome_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      tagged = requests_repo.tagged_requests(result.test_session_id,
                                             [DaVinciPASTestKit::OPERATION_FAILURE_WORKFLOW_TAG,
                                              DaVinciPASTestKit::SUBMIT_TAG])
      expect(tagged.length).to be(1)
    end
  end

  describe 'when operation_failure_operation_outcome input is absent' do
    it 'skips before waiting' do
      inputs = { session_url_path: }
      result = run(described_class, inputs)
      expect(result.result).to eq('skip')
    end
  end

  describe 'when operation_failure_operation_outcome input is not valid JSON' do
    it 'fails before waiting' do
      inputs = { session_url_path:, operation_failure_operation_outcome: 'not json' }
      result = run(described_class, inputs)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/must be valid JSON/i)
    end
  end
end
