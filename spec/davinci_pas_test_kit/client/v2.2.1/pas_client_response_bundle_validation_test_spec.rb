require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/workflows/' \
                 'pas_client_response_bundle_validation_test'
require_relative '../../../support/custom_extension_validator_stub'
require_relative '../../../support/client_suite_test_lookup'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasClientResponseBundleValidationTest, :request do
  include ClientSuiteTestLookup

  include_context 'with custom extension validator stub'

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  # The validators are defined on the suite, so run the copy of the test within it.
  let(:test) { v221_client_workflow_test(:pas_client_v221_approval_group, described_class.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:request_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:response_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle.json')))
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

  describe 'with a response Inferno generated from the request' do
    let(:session_url_path) { '1234' }
    let(:approval_submit_test) do
      v221_client_workflow_test(:pas_client_v221_approval_group, :pas_client_v221_approval_submit_test)
    end

    # The request with the extension added to the elements of the Claim that Inferno copies into the
    # ClaimResponse it generates, and to the Patient, which it echoes.
    def request_with_extension(extension)
      request_bundle_hash.deep_dup.tap do |bundle|
        claim = bundle['entry'].first['resource']
        claim['extension'] << extension
        claim['identifier'].first['extension'] << extension
        claim['type']['extension'] = [extension]
        claim['type']['coding'].first['extension'] = [extension]
        claim['patient']['extension'] = [extension]
        claim['item'].first['productOrService']['extension'] = [extension]
        patient = bundle['entry'].find { |entry| entry['resource']['resourceType'] == 'Patient' }['resource']
        patient['extension'] << extension
        patient['_gender'] = { 'extension' => [extension] }
      end
    end

    # Has Inferno generate the response to the request, then validates it.
    def run_with_generated_response(request_bundle)
      submit_result = run(approval_submit_test, session_url_path:)
      expect(submit_result.result).to eq('wait')
      post_json("/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}", request_bundle)
      expect(last_response.status).to eq(200)

      run(test)
    end

    it 'passes when the request has custom extensions' do
      result = run_with_generated_response(request_with_extension(custom_extension))

      expect(result.result).to eq('pass')
      expect(result_messages(result, 'error')).to be_empty
      expect(last_response.body).to include(custom_extension_url) # kept on the echoed Patient
    end
  end

  describe 'with multiple requests in the must support workflow' do
    let(:must_support_test) do
      v221_client_suite_test(:pas_client_v221_must_support_no_auth, :pas_client_v221_must_support_receive,
                             described_class.id)
    end

    def create_must_support_request(request_bundle, response_bundle)
      repo_create(
        :request,
        direction: 'incoming',
        url: submit_url,
        test_session_id: test_session.id,
        result:,
        request_body: request_bundle.to_json,
        response_body: response_bundle.to_json,
        tags: [DaVinciPASTestKit::MUST_SUPPORT_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
        status: 200
      )
    end

    # Each response may only echo the extensions in its own request.
    it 'does not allow an echoed extension from a different request' do
      request_with_extension = with_custom_extension(request_bundle_hash, 'Patient')
      patient_with_extension = request_with_extension['entry']
        .find { |entry| entry['resource']['resourceType'] == 'Patient' }
      response_with_extension = response_bundle_hash.merge(
        'entry' => response_bundle_hash['entry'].map do |entry|
          entry['resource']['resourceType'] == 'Patient' ? patient_with_extension : entry
        end
      )
      create_must_support_request(request_with_extension, response_with_extension)
      create_must_support_request(request_bundle_hash, response_with_extension)

      result = run(must_support_test)

      expect(result.result).to eq('skip')
      errors = result_messages(result, 'error')
      expect(errors).to include(a_string_starting_with('Response 2:')
        .and(a_string_including("extension #{custom_extension_url} in an echoed resource is not in the source " \
                                'resource at this element')))
      expect(errors).to_not include(a_string_starting_with('Response 1:'))
    end
  end
end
