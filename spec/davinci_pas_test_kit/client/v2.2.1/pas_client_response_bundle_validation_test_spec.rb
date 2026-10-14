require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/workflows/' \
                 'pas_client_response_bundle_validation_test'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasClientResponseBundleValidationTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  # The validators are defined on the suite, so run the copy of the test within it.
  let(:test) do
    DaVinciPASTestKit::DaVinciPASV221::ClientSuite
      .groups.flat_map(&:groups)
      .find { |group| group.id.to_s.end_with?('pas_client_v221_approval_group') }
      .tests.find { |child| child.id.to_s.end_with?(described_class.id.to_s) }
  end
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:custom_extension_url) { 'urn:inferno-custom' }
  let(:custom_extension) { { 'url' => custom_extension_url, 'valueString' => 'x' } }
  let(:request_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  # The fixture's authorized quantity has no unit, which the v2.2.1 datatype constraints require (prof-2).
  let(:response_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle.json'))).tap do |bundle|
      authorized_detail = bundle['entry'].first['resource']['item'].first['extension']
        .find { |extension| extension['url'].end_with?('extension-itemAuthorizedDetail') }
      quantity = authorized_detail['extension'].find { |extension| extension['url'] == 'quantity' }
      quantity['valueQuantity']['unit'] = 'unit'
    end
  end

  # Inferno's validator stub: the strict :no_custom_extensions validator (sent extensions: []) reports
  # the HL7 validator's unknown extension error for each custom extension on the validated resource,
  # and the :default validator (extensions: ['any']) allows them. Everything else is valid.
  before do
    # Reference-following FHIRPath lookups aren't needed for these resources.
    stub_request(:post, %r{/fhirpath/evaluate}).to_return(status: 200, body: '[]')
    stub_request(:post, validation_url).to_return do |request|
      body = JSON.parse(request.body)
      context = body['validationContext'] || body['cliContext']
      resource = JSON.parse(body['filesToValidate'].first['fileContent'])
      issues =
        if context['extensions'] == []
          Array(resource['extension']).each_with_index.filter_map do |extension, index|
            next unless extension['url'] == custom_extension_url

            { level: 'ERROR', location: "#{resource['resourceType']}.extension[#{index}]",
              message: "The extension #{custom_extension_url} could not be found so is not allowed here" }
          end
        else
          []
        end
      { status: 200, body: { outcomes: [{ issues: }] }.to_json }
    end
  end

  # Adds the custom extension to the bundle's first entry of the resource type.
  def with_custom_extension(bundle_hash, resource_type)
    bundle_hash.deep_dup.tap do |copy|
      resource = copy['entry'].find { |entry| entry['resource']['resourceType'] == resource_type }['resource']
      resource['extension'] = Array(resource['extension']) + [custom_extension]
    end
  end

  def run_test(request_bundle, response_bundle)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body: request_bundle.to_json,
      response_body: response_bundle.to_json,
      tags: [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
      status: 200
    )
    run(test)
  end

  def result_messages(result, type)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |m| m.type == type }.map(&:message)
  end

  it 'skips when the response has a custom extension' do
    result = run_test(request_bundle_hash, with_custom_extension(response_bundle_hash, 'ClaimResponse'))

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('Non-conformant response Bundles')
    expect(result_messages(result, 'error'))
      .to include(a_string_including("The extension #{custom_extension_url} could not be found"))
  end

  it 'allows a custom extension on a resource echoed unchanged from the request' do
    request_bundle = with_custom_extension(request_bundle_hash, 'Patient')
    request_patient_entry = request_bundle['entry'].find { |entry| entry['resource']['resourceType'] == 'Patient' }
    response_bundle = response_bundle_hash.merge(
      'entry' => response_bundle_hash['entry'].map do |entry|
        entry['resource']['resourceType'] == 'Patient' ? request_patient_entry : entry
      end
    )

    result = run_test(request_bundle, response_bundle)

    expect(result.result).to eq('pass')
    expect(result_messages(result, 'error')).to be_empty
    expect(result_messages(result, 'info')).to include(
      a_string_including("Patient #{request_patient_entry['fullUrl']} echoes the Patient in the request")
        .and(a_string_including(custom_extension_url))
    )
  end
end
