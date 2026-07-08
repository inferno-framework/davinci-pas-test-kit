require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/urls'
require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/error_handling/' \
                 'pas_client_processing_error_submit_test'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientProcessingErrorSubmitTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:submit_request_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:processing_error_bundle_json) do
    JSON.generate(
      resourceType: 'Bundle',
      id: 'processing-error-bundle-example',
      meta: { profile: ['http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle'] },
      type: 'collection',
      timestamp: '2024-01-30T13:29:32Z',
      entry: [{
        fullUrl: 'urn:uuid:a1b2c3d4-error-0000-0000-000000000001',
        resource: {
          resourceType: 'ClaimResponse',
          id: 'a1b2c3d4-error-0000-0000-000000000001',
          status: 'active',
          type: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/claim-type', code: 'professional' }] },
          use: 'preauthorization',
          patient: { reference: 'urn:uuid:0b321e9e-571b-4f83-8cea-fa23424383bb' },
          created: '2024-01-30T13:29:32Z',
          insurer: { display: 'Test Insurer' },
          request: { reference: 'urn:uuid:claim-reference' },
          outcome: 'error',
          error: [{
            code: {
              coding: [{ system: 'http://terminology.hl7.org/CodeSystem/adjudication-error',
                         code: '4', display: 'Payer Unrecognized' }]
            }
          }]
        }
      }]
    )
  end

  describe 'when the tester provides a valid processing error bundle' do
    it 'passes when a submit request is received' do
      inputs = { session_url_path:, processing_error_response: processing_error_bundle_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'returns HTTP status 200' do
      inputs = { session_url_path:, processing_error_response: processing_error_bundle_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
    end

    it 'returns the processing error bundle body' do
      inputs = { session_url_path:, processing_error_response: processing_error_bundle_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      fhir_body = FHIR.from_contents(last_response.body)
      expect(fhir_body).to be_a(FHIR::Bundle)
      claim_response = fhir_body.entry.first&.resource
      expect(claim_response).to be_a(FHIR::ClaimResponse)
      expect(claim_response.error).to_not be_empty
    end

    it 'tags submit requests with PROCESSING_ERROR_WORKFLOW_TAG and SUBMIT_TAG' do
      inputs = { session_url_path:, processing_error_response: processing_error_bundle_json }
      result = run(described_class, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      tagged = requests_repo.tagged_requests(result.test_session_id,
                                             [DaVinciPASTestKit::PROCESSING_ERROR_WORKFLOW_TAG,
                                              DaVinciPASTestKit::SUBMIT_TAG])
      expect(tagged.length).to be(1)
    end
  end

  describe 'when processing_error_response input is absent' do
    it 'skips before waiting' do
      inputs = { session_url_path: }
      result = run(described_class, inputs)
      expect(result.result).to eq('skip')
    end
  end

  describe 'when processing_error_response input is not valid JSON' do
    it 'fails before waiting' do
      inputs = { session_url_path:, processing_error_response: 'not json' }
      result = run(described_class, inputs)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/must be valid JSON/i)
    end
  end
end
