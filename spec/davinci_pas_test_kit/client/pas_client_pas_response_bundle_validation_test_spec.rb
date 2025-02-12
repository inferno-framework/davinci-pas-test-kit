RSpec.describe DaVinciPASTestKit::DaVinciPASV201::ClientPasResponseBundleValidationTest, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:access_token) { '1234' }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:validator_url) { ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL') }
  let(:fhirpath_url) { 'https://example.com/fhirpath/evaluate' }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:operation_outcome_success) do
    {
      outcomes: [{
        issues: []
      }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
    }
  end
  let(:valid_response_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
  end
  let(:approval_test) do
    Class.new(DaVinciPASTestKit::DaVinciPASV201::ClientPasResponseBundleValidationTest) do
      fhir_resource_validator do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')

        cli_context do
          txServer nil
          displayWarnings true
          disableDefaultResourceFetcher true
        end

        igs('hl7.fhir.us.davinci-pas#2.0.1')
      end

      input :approval_json_response, optional: true

      config({ options: { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG } })
    end
  end

  def create_submit_response(bundle_string, tags_list)
    headers ||= [
      {
        type: 'request',
        name: 'Authorization',
        value: "Bearer #{access_token}"
      }
    ]
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      response_body: bundle_string,
      tags: tags_list,
      status: 201,
      headers:
    )
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

  describe 'when verifying submit responses' do
    it 'skips when no tests previously made' do
      result = run(approval_test)
      expect(result.result).to eq('skip')
    end

    it 'skips when no requests made for the specific workflow' do
      create_submit_response(valid_response_string,
                             [DaVinciPASTestKit::DENIAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
      result = run(approval_test)
      expect(result.result).to eq('skip')
    end

    it 'passes with a valid response' do
      stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: operation_outcome_success.to_json)
      stub_request(:post, /#{fhirpath_url}\?path=ClaimResponse.*/)
        .to_return(status: 200, body: [].to_json)
      stub_request(:post, /#{fhirpath_url}\?path=Patient.*/)
        .to_return(status: 200, body: [].to_json)
      stub_request(:post, /#{fhirpath_url}\?path=Organization.*/)
        .to_return(status: 200, body: [].to_json)
      stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.patient")
        .to_return(status: 200, body: [{ type: 'Reference',
                                         element: { reference: 'Patient/SubscriberExample' } }].to_json)
      stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.insurer")
        .to_return(status: 200, body: [{ type: 'Reference',
                                         element: { reference: 'Organization/InsurerExample' } }].to_json)
      stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.requestor")
        .to_return(status: 200, body: [{ type: 'Reference',
                                         element: { reference: 'Organization/UMOExample' } }].to_json)
      create_submit_response(valid_response_string,
                             [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                              DaVinciPASTestKit::SUBMIT_TAG])

      inputs = { approval_json_response: nil }
      result = run(approval_test, inputs)

      expect(result.result).to eq('pass')
    end

    describe 'and failing' do
      it 'indicates the response was generated when no user input' do
        create_submit_response('NOT JSON',
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                                DaVinciPASTestKit::SUBMIT_TAG])

        inputs = { approval_json_response: nil }
        result = run(approval_test, inputs)

        expect(result.result).to eq('skip')
        expect(result.result_message).to match(/Invalid response generated from the submitted claim:/)
      end

      it 'indicates the response came from the user when user input provided' do
        create_submit_response('NOT JSON',
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                                DaVinciPASTestKit::SUBMIT_TAG])

        inputs = { approval_json_response: 'NOT JSON' }
        result = run(approval_test, inputs)

        expect(result.result).to eq('skip')
        expect(result.result_message).to match(/Invalid response generated from provided input/)
      end
    end
  end
end
