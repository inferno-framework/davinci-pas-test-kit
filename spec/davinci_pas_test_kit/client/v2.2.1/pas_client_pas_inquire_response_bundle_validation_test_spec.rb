RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasClientInquireResponseBundleValidationTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:access_token) { '1234' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:inquire_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::INQUIRE_PATH}" }
  let(:valid_bundle_json) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_inquire_response_bundle.json'))
  end
  let(:invalid_bundle_json) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'invalid_first_entry_response_bundle.json'))
  end
  let(:valid_bundle) { FHIR.from_contents(valid_bundle_json) }
  let(:invalid_bundle) { FHIR.from_contents(invalid_bundle_json) }

  let(:test) do
    Class.new(DaVinciPASTestKit::DaVinciPASV221::PasClientInquireResponseBundleValidationTest) do
      input :inquire_json_response, optional: true

      config({ options: { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG } })
    end
  end

  before do
    # Profile conformance is validated by hitting the external FHIR validator service, which
    # these tests don't need - they're only exercising the Parameters/Bundle routing this test
    # does itself, not conformance checking (covered by the cross_suite bundle validation specs).
    # Flag a Bundle as nonconformant based on its first entry, the same signal
    # invalid_first_entry_response_bundle.json/valid_pa_inquire_response_bundle.json differ
    # on, so a stubbed Bundle can still fail in a way perform_bundle_validation reports.
    allow_any_instance_of(test).to receive(:validate_resources_conformance_against_profile) do |instance, bundle, *|
      first_type = bundle.entry&.first&.resource.try(:resourceType)
      instance.validation_error_messages << 'Stubbed non-conformance error' unless first_type == 'ClaimResponse'
    end
  end

  def create_inquire_response(body, tags_list)
    headers = [{ type: 'request', name: 'Authorization', value: "Bearer #{access_token}" }]
    repo_create(
      :request,
      direction: 'incoming',
      url: inquire_url,
      test_session_id: test_session.id,
      result:,
      response_body: body,
      tags: tags_list,
      status: 201,
      headers:
    )
  end

  def parameters_json(*bundles)
    parameters = FHIR::Parameters.new
    bundles.each do |bundle|
      parameters.parameter << FHIR::Parameters::Parameter.new(name: 'return', resource: bundle)
    end
    parameters.to_json
  end

  def run_test(body)
    create_inquire_response(body, [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::INQUIRE_TAG])
    run(test, inquire_json_response: nil)
  end

  it 'skips when no requests were made' do
    result = run(test, inquire_json_response: nil)
    expect(result.result).to eq('skip')
  end

  it 'passes for a Parameters resource wrapping a single conformant Bundle' do
    result = run_test(parameters_json(valid_bundle))

    expect(result.result).to eq('pass')
  end

  it 'passes for a Parameters resource wrapping multiple conformant Bundles' do
    result = run_test(parameters_json(valid_bundle, valid_bundle))

    expect(result.result).to eq('pass')
  end

  it 'passes for a Parameters resource with no return parameters' do
    result = run_test(parameters_json)

    expect(result.result).to eq('pass')
  end

  it 'skips and labels the failing Bundle when one of several is not conformant' do
    result = run_test(parameters_json(valid_bundle, invalid_bundle))

    expect(result.result).to eq('skip')
    messages = entity_result_messages(test)
    expect(messages.map(&:message).join).to include('Response 1 Bundle 2: Stubbed non-conformance error')
  end

  it 'skips but still validates a bare Bundle received instead of Parameters' do
    result = run_test(valid_bundle_json)

    expect(result.result).to eq('skip')
    messages = entity_result_messages(test)
    expect(messages.map(&:message).join).to include('expected a Parameters resource, got Bundle')
  end

  it 'skips for a resource that is neither Parameters nor Bundle' do
    claim_json = FHIR::Claim.new(status: 'active').to_json

    result = run_test(claim_json)

    expect(result.result).to eq('skip')
    messages = entity_result_messages(test)
    expect(messages.map(&:message).join).to include('expected a Parameters resource, got Claim')
  end

  it 'skips for invalid JSON' do
    result = run_test('NOT JSON')

    expect(result.result).to eq('skip')
  end

  def entity_result_messages(runnable)
    Inferno::Repositories::Results.new
      .current_results_for_test_session_and_runnables(test_session.id, [runnable])
      .first
      .messages
  end
end
