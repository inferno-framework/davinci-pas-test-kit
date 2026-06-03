RSpec.describe DaVinciPASTestKit::PasClaimResponseDecisionTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:pa_response_valid_bundle) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle.json'))
  end
  let(:pa_response_valid_bundle_denial) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle_denial.json'))
  end

  let(:test) do
    Class.new(described_class) do
      config(
        options: {
          use_case: 'approval',
          operation: 'submit'
        }
      )
    end
  end

  def create_submit_request(bundle_string, tags_list)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      response_body: bundle_string,
      tags: tags_list,
      status: 201
    )
  end

  it 'skips if no requests made' do
    result = run(test)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No Bundles to check/)
  end

  it 'fails if no requests made for the right workflow' do
    create_submit_request(pa_response_valid_bundle,
                          [DaVinciPASTestKit::PENDED_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
    result = run(test)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No Bundles to check/)
  end

  it 'fails if no responses are FHIR Bundles' do
    tags = [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG]
    create_submit_request(nil, tags)
    create_submit_request('not json', tags)
    create_submit_request(FHIR::Patient.new.to_json, tags)
    result = run(test)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No Bundles to check/)
  end

  it 'passes when valid Bundles were returned' do
    create_submit_request(pa_response_valid_bundle,
                          [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])

    result = run(test)
    expect(result.result).to eq('pass')
  end

  it 'only analyzes duplicate Bundles once' do
    call_count = 0
    allow_any_instance_of(test)
      .to receive(:response_has_expected_adjudication_code?) { call_count += 1 }.and_return(true)
    create_submit_request(pa_response_valid_bundle,
                          [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
    create_submit_request(pa_response_valid_bundle,
                          [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])

    result = run(test)
    expect(result.result).to eq('pass')
    expect(call_count).to eq(1)
  end

  it 'fails if the wrong adjudication code found' do
    create_submit_request(pa_response_valid_bundle,
                          [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
    create_submit_request(pa_response_valid_bundle_denial,
                          [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])

    result = run(test)
    expect(result.result).to eq('fail')
    expect(result.result_message)
      .to match(/One or more response Bundles did not have the expected adjudication code A1./)
  end
end
