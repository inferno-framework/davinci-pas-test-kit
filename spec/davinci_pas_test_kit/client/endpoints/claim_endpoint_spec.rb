require_relative '../../../../lib/davinci_pas_test_kit/client/v2.0.1/urls'

# Exercises the ClaimEndpoint response selection behavior for the must support workflow
RSpec.describe DaVinciPASTestKit::AbstractGatherMustSupportTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v201' }

  describe 'must support response selection' do
    let(:session_url_path) { '1234' }
    let(:test) do
      Class.new(described_class) do
        include DaVinciPASTestKit::DaVinciPASV201::URLs

        def suite_id
          'davinci_pas_client_suite_v201'
        end
      end
    end
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
    let(:inquire_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::INQUIRE_PATH}" }
    let(:submit_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
    end
    let(:inquire_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_inquire_bundle_v110.json')))
    end

    def response_bundle(id:, fixture: 'valid_pa_response_bundle.json')
      bundle = JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', fixture)))
      bundle['entry'][0]['resource']['id'] = id
      bundle
    end

    def wrapped_response_bundle(id:, criteria:, fixture: 'valid_pa_response_bundle.json')
      { 'criteria' => criteria, 'bundle' => response_bundle(id:, fixture:) }
    end

    def stub_fhirpath_service(expression, results)
      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => expression })
        .to_return(status: 200, body: results.to_json)
    end

    def returned_claim_response
      FHIR.from_contents(last_response.body).entry[0].resource
    end

    it 'returns a tester-provided response given as a single bare bundle' do
      inputs = { session_url_path:, ms_submit_responses: response_bundle(id: 'single-bundle').to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('single-bundle')
    end

    it 'returns a tester-provided response given as a single wrapper object' do
      inputs = { session_url_path:,
                 ms_submit_responses: wrapped_response_bundle(id: 'wrapped-bundle', criteria: nil).to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('wrapped-bundle')
    end

    it 'returns the bundle of the first entry when no entries specify criteria' do
      responses = [response_bundle(id: 'first'), response_bundle(id: 'second')]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('first')
    end

    it 'falls through to a bare bundle when earlier wrapper criteria do not match' do
      responses = [wrapped_response_bundle(id: 'for-later-requests', criteria: { 'requestRange' => '2-9' }),
                   response_bundle(id: 'fallback')]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('fallback')
    end

    # Request numbering relies on the URLs of previously persisted requests, which are built
    # from REQUEST_PATH. Puma sets it in production, but Rack::Test does not, so it must be
    # supplied explicitly for the persisted requests to be countable.
    def post_json_with_request_path(url, json)
      post(url, json.to_json, 'CONTENT_TYPE' => 'application/json', 'REQUEST_PATH' => url)
    end

    it 'selects bundles by request range across successive requests' do
      responses = [wrapped_response_bundle(id: 'for-request-1', criteria: { 'requestRange' => '1' }),
                   wrapped_response_bundle(id: 'for-later-requests', criteria: { 'requestRange' => '2-3' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json_with_request_path(submit_url, submit_request_json)
      expect(returned_claim_response.id).to eq('for-request-1')

      post_json_with_request_path(submit_url, submit_request_json)
      expect(returned_claim_response.id).to eq('for-later-requests')
    end

    it 'selects the first entry whose fhirpath criteria evaluate to true against the request' do
      responses = [wrapped_response_bundle(id: 'not-selected',
                                           criteria: { 'fhirpath' => 'Bundle.identifier.exists()' }),
                   wrapped_response_bundle(id: 'selected', criteria: { 'fhirpath' => 'Bundle.id.exists()' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.identifier.exists()', [{ type: 'boolean', element: false }])
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: true }])
      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('selected')
    end

    it 'returns only the inner bundle of a selected wrapper' do
      responses = [wrapped_response_bundle(id: 'with-criteria', criteria: { 'requestRange' => '1-9' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('with-criteria')
      returned = JSON.parse(last_response.body)
      expect(returned['resourceType']).to eq('Bundle')
      expect(returned).to_not have_key('criteria')
      expect(returned).to_not have_key('bundle')
    end

    it 'replaces {{fhirpath}} tokens with values evaluated against the request' do
      bundle = response_bundle(id: 'token-bundle')
      bundle['entry'][0]['resource']['preAuthRef'] = '{{Bundle.entry.first().resource.id}}'
      inputs = { session_url_path:, ms_submit_responses: bundle.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.entry.first().resource.id',
                            [{ type: 'string', element: 'ReferralAuthorizationExample' }])
      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.preAuthRef).to eq('ReferralAuthorizationExample')
    end

    it 'keeps the returned bundle parseable with consistent references after token replacement' do
      token = '{{Bundle.entry.first().resource.id}}'
      bundle = response_bundle(id: 'consistency-bundle')
      patient_entry = bundle['entry'].find { |e| e['resource']['resourceType'] == 'Patient' }
      patient_entry['fullUrl'] = "https://example.org/fhir/Patient/#{token}"
      patient_entry['resource']['id'] = token
      bundle['entry'][0]['resource']['patient']['reference'] = "Patient/#{token}"
      inputs = { session_url_path:, ms_submit_responses: { 'bundle' => bundle }.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.entry.first().resource.id',
                            [{ type: 'string', element: 'ReferralAuthorizationExample' }])
      post_json(submit_url, submit_request_json)

      returned = FHIR.from_contents(last_response.body)
      expect(returned).to be_a(FHIR::Bundle)
      full_urls = returned.entry.map(&:fullUrl)
      expect(full_urls.uniq.length).to eq(full_urls.length)
      returned_patient = returned.entry.find { |e| e.resource.resourceType == 'Patient' }
      expect(returned_patient.fullUrl).to eq('https://example.org/fhir/Patient/ReferralAuthorizationExample')
      expect(returned_patient.resource.id).to eq('ReferralAuthorizationExample')
      expect(returned.entry[0].resource.patient.reference).to eq('Patient/ReferralAuthorizationExample')
    end

    it 'generates a default response when no provided entry matches' do
      responses = [wrapped_response_bundle(id: 'never-selected', criteria: { 'requestRange' => '5' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(returned_claim_response.id).to_not eq('never-selected')
    end

    it 'generates a default response when the input is not parseable' do
      inputs = { session_url_path:, ms_submit_responses: 'not json' }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
    end

    it 'serves tester-provided bundles for inquire requests' do
      responses = [response_bundle(id: 'inquire-bundle', fixture: 'valid_pa_inquire_response_bundle.json')]
      inputs = { session_url_path:, ms_inquire_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(inquire_url, inquire_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('inquire-bundle')
    end
  end
end
