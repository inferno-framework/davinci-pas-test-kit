require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/error_handling/' \
                 'pas_client_processing_error_response_validation_test'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientProcessingErrorResponseValidationTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  # The validators are defined on the suite, so run the copy of the test within it.
  let(:test) do
    DaVinciPASTestKit::DaVinciPASV221::ClientSuite
      .groups.flat_map(&:groups)
      .find { |group| group.id.to_s.end_with?('pas_client_v221_processing_error_group') }
      .tests.find { |child| child.id.to_s.end_with?(described_class.id.to_s) }
  end
  let(:submit_url) { "/custom/#{suite_id}/1234#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:custom_extension_url) { 'urn:inferno-custom' }
  let(:custom_extension) { { 'url' => custom_extension_url, 'valueString' => 'x' } }
  let(:request_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:request_patient_entry) { request_bundle_hash['entry'].find { |e| e['resource']['resourceType'] == 'Patient' } }
  let(:claim_response_entry) do
    {
      'fullUrl' => 'urn:uuid:a1b2c3d4-error-0000-0000-000000000001',
      'resource' => {
        'resourceType' => 'ClaimResponse',
        'id' => 'a1b2c3d4-error-0000-0000-000000000001',
        'status' => 'active',
        'type' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/claim-type',
                                   'code' => 'professional' }] },
        'use' => 'preauthorization',
        'patient' => { 'reference' => request_patient_entry['fullUrl'] },
        'created' => '2024-01-30T13:29:32Z',
        'insurer' => { 'display' => 'Test Insurer' },
        'outcome' => 'error',
        'error' => [{
          'code' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication-error',
                                     'code' => '4', 'display' => 'Payer Unrecognized' }] }
        }]
      }
    }
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

  def with_extension(entry, extension)
    entry.deep_dup.tap { |copy| copy['resource']['extension'] = Array(copy['resource']['extension']) + [extension] }
  end

  def response_bundle_json(*entries)
    {
      'resourceType' => 'Bundle',
      'id' => 'processing-error-bundle-example',
      'meta' => { 'profile' => ['http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle'] },
      'type' => 'collection',
      'timestamp' => '2024-01-30T13:29:32Z',
      'entry' => entries
    }.to_json
  end

  def create_processing_error_request(request_body, response_body)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body:,
      response_body:,
      tags: [DaVinciPASTestKit::PROCESSING_ERROR_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
      status: 200
    )
  end

  # The suite's copy of the test requires the tester-provided response input, although the test
  # itself validates the response body that was actually returned.
  def run_test(request_bundle_json, response_bundle_json)
    create_processing_error_request(request_bundle_json, response_bundle_json)
    run(test, processing_error_response: response_bundle_json)
  end

  def result_messages(result, type)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |m| m.type == type }.map(&:message)
  end

  it 'skips when no Processing Error $submit requests were received' do
    result = run(test, processing_error_response: response_bundle_json(claim_response_entry))

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No responses to verify')
  end

  it 'passes for a conformant response Bundle with an error entry' do
    result = run_test(request_bundle_hash.to_json, response_bundle_json(claim_response_entry, request_patient_entry))

    expect(result.result).to eq('pass')
    expect(result_messages(result, 'error')).to be_empty
  end

  it 'skips when the ClaimResponse has a custom extension' do
    response = response_bundle_json(with_extension(claim_response_entry, custom_extension), request_patient_entry)

    result = run_test(request_bundle_hash.to_json, response)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('Bundle and/or entry resources are not conformant')
    expect(result_messages(result, 'error'))
      .to include(a_string_including("The extension #{custom_extension_url} could not be found"))
  end

  describe 'with a Patient echoed from a request that gave it a custom extension' do
    let(:request_patient_with_extension) { with_extension(request_patient_entry, custom_extension) }
    let(:request_json) do
      request_bundle_hash.merge(
        'entry' => request_bundle_hash['entry'].map do |entry|
          entry == request_patient_entry ? request_patient_with_extension : entry
        end
      ).to_json
    end

    it 'allows the extension when the Patient is echoed unchanged' do
      response = response_bundle_json(claim_response_entry, request_patient_with_extension)

      result = run_test(request_json, response)

      expect(result.result).to eq('pass')
      expect(result_messages(result, 'info')).to include(
        a_string_including("Patient #{request_patient_entry['fullUrl']} echoes the Patient in the request")
          .and(a_string_including('these extensions unchanged from the request are allowed in it:'))
          .and(a_string_including(custom_extension_url))
      )
      expect(result_messages(result, 'error')).to be_empty
    end

    it 'reports an error when the echoed extension value was changed' do
      changed_patient = with_extension(request_patient_entry, custom_extension.merge('valueString' => 'changed'))
      response = response_bundle_json(claim_response_entry, changed_patient)

      result = run_test(request_json, response)

      expect(result.result).to eq('skip')
      expect(result_messages(result, 'error')).to include(
        a_string_including("echoed extension #{custom_extension_url} contained a different value than in the " \
                           'source resource')
      )
    end
  end
end
