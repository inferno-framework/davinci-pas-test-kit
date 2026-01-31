RSpec.describe DaVinciPASTestKit::ServerRequestBundleValidationTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:pa_request_valid_bundle) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  let(:test) do
    Class.new(described_class) do
      config(
        options: {
          use_case: 'approval',
          operation: 'submit',
          ig_version: 'v2.0.1'
        }
      )
    end
  end

  def entity_result_messages(runnable)
    results_repo.current_results_for_test_session_and_runnables(test_session.id, [runnable])
      .first
      .messages
  end

  it 'skips if no input provided' do
    result = run(test)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No bundle request input provided./)
  end

  it 'fails if input is not json' do
    result = run(test, bundle_payload: 'not json')
    expect(result.result).to eq('fail')
    expect(result.result_message)
      .to match(/Invalid JSON. Provide valid json to use for the \$submit during the Approval workflow./)
  end

  it 'fails if no inputs are Bundles' do
    result = run(test, bundle_payload: ['string data', { resourceType: 'Patient' }].to_json)
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Provided input is not a Bundle or list of Bundles./)
  end

  it 'passes when one valid Bundle is provided' do
    allow_any_instance_of(test).to receive(:perform_bundle_validation).and_return(nil)
    allow_any_instance_of(test).to receive(:validation_error_messages).and_return([])

    result = run(test, bundle_payload: pa_request_valid_bundle)
    expect(result.result).to eq('pass')
  end

  it 'passes when multiple valid Bundles are provided' do
    allow_any_instance_of(test).to receive(:perform_bundle_validation).and_return(nil)
    allow_any_instance_of(test).to receive(:validation_error_messages).and_return([])

    result = run(test, bundle_payload: "[#{pa_request_valid_bundle},#{FHIR::Bundle.new.to_json}]")
    expect(result.result).to eq('pass')
  end

  it 'only analyzes duplicate Bundles once' do
    call_count = 0
    allow_any_instance_of(test).to receive(:perform_bundle_validation) { call_count += 1 }.and_return(nil)
    allow_any_instance_of(test).to receive(:validation_error_messages).and_return([])

    result = run(test, bundle_payload: "[#{pa_request_valid_bundle},#{pa_request_valid_bundle}]")
    expect(result.result).to eq('pass')
    expect(call_count).to eq(1)
  end

  it 'skips if validation errors found' do
    allow_any_instance_of(test).to receive(:perform_bundle_validation).and_return(nil)
    allow_any_instance_of(test).to receive(:validation_error_messages)
      .and_return(['this is an error', 'this is another error'])

    result = run(test, bundle_payload: pa_request_valid_bundle)
    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/Bundle\(s\) provided are not conformant. Check messages for issues found./)
    messages = entity_result_messages(test)
    expect(messages.size).to eq(2)
    expect(messages.all? { |message| message.type == 'error' }).to be(true)
    expect(messages[0].message).to eq('this is an error')
    expect(messages[1].message).to eq('this is another error')
  end
end
