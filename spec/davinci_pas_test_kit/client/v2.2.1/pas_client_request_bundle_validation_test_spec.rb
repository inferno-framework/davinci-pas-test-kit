require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/workflows/' \
                 'pas_client_request_bundle_validation_test'
require_relative '../../../support/client_suite_test_lookup'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasClientRequestBundleValidationTest, :request do
  include ClientSuiteTestLookup

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  # The validators are defined on the suite, so run the copy of the test within it.
  let(:test) { v221_client_workflow_test(:pas_client_v221_approval_group, described_class.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:custom_extension_url) { 'urn:inferno-custom' }
  let(:request_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end

  def validation_context_from(request)
    body = JSON.parse(request.body)
    body['validationContext'] || body['cliContext']
  end

  before do
    # Reference-following FHIRPath lookups aren't needed for these resources.
    stub_request(:post, %r{/fhirpath/evaluate}).to_return(status: 200, body: '[]')
    stub_request(:post, validation_url).to_return(status: 200, body: { outcomes: [{ issues: [] }] }.to_json)
  end

  # Requests come from the system under test, so unlike responses Inferno sends (see
  # pas_client_response_bundle_validation_test_spec.rb), they may contain custom extensions.
  it 'validates a request with a custom extension using the validator that allows any extension' do
    request_bundle = request_bundle_hash.deep_dup
    request_bundle['entry'].first['resource']['extension'] << { 'url' => custom_extension_url, 'valueString' => 'x' }
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body: request_bundle.to_json,
      tags: [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
      status: 200
    )

    result = run(test)

    expect(result.result).to eq('pass')
    expect(a_request(:post, validation_url).with { |req| validation_context_from(req)['extensions'] != ['any'] })
      .to_not have_been_made
  end
end
