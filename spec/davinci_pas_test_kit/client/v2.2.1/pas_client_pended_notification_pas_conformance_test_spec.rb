require_relative '../../../../lib/davinci_pas_test_kit/pas_notification_conformance_test'
require_relative '../../../support/custom_extension_validator_stub'
require_relative '../../../support/client_suite_test_lookup'

RSpec.describe DaVinciPASTestKit::NotificationPASConformanceTest, :request do
  include ClientSuiteTestLookup

  include_context 'with custom extension validator stub'

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  # The validators are defined on the suite, so run the copy of the test in the pended group, which
  # validates the focus Bundle without allowing custom extensions.
  let(:test) { v221_client_workflow_test(:pas_client_v221_pended_group, described_class.id) }
  let(:request_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:response_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle.json')))
  end

  def notification_body(focus_bundle)
    {
      resourceType: 'Bundle',
      type: 'history',
      entry: [
        {
          fullUrl: 'urn:uuid:status-entry',
          resource: {
            resourceType: 'Parameters',
            parameter: [
              { name: 'subscription', valueReference: { reference: 'Subscription/123' } },
              { name: 'type', valueCode: 'event-notification' },
              { name: 'notification-event',
                part: [{ name: 'focus', valueReference: { reference: 'urn:uuid:focus-bundle' } }] }
            ]
          }
        },
        { fullUrl: 'urn:uuid:focus-bundle', resource: focus_bundle }
      ]
    }.to_json
  end

  # Adds the custom extension to the bundle's first entry of the resource type.
  def with_custom_extension(bundle_hash, resource_type)
    bundle_hash.deep_dup.tap do |copy|
      resource = copy['entry'].find { |entry| entry['resource']['resourceType'] == resource_type }['resource']
      resource['extension'] = Array(resource['extension']) + [custom_extension]
    end
  end

  def run_test(request_bundle, focus_bundle)
    repo_create(:request, direction: 'incoming', url: "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}",
                          test_session_id: test_session.id, result:, request_body: request_bundle.to_json,
                          tags: [DaVinciPASTestKit::SUBMIT_TAG, DaVinciPASTestKit::PENDED_WORKFLOW_TAG],
                          status: 200)
    repo_create(:request, direction: 'outgoing', url: 'http://example.com/notification',
                          test_session_id: test_session.id, result:, request_body: notification_body(focus_bundle),
                          tags: [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG], status: 200)
    run(test)
  end

  def result_messages(result, type)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |m| m.type == type }.map(&:message)
  end

  it 'passes when the focus Bundle has no custom extensions' do
    result = run_test(request_bundle_hash, response_bundle_hash)

    expect(result.result).to eq('pass')
  end

  it 'fails when the focus Bundle has a custom extension' do
    result = run_test(request_bundle_hash, with_custom_extension(response_bundle_hash, 'ClaimResponse'))

    expect(result.result).to eq('fail')
    expect(result_messages(result, 'error')).to include(
      a_string_including('Focus Bundle `urn:uuid:focus-bundle`')
        .and(a_string_including("The extension #{custom_extension_url} could not be found"))
    )
  end

  it 'allows a custom extension on a resource echoed unchanged from the pended $submit request' do
    request_bundle = with_custom_extension(request_bundle_hash, 'Patient')
    request_patient_entry = request_bundle['entry'].find { |entry| entry['resource']['resourceType'] == 'Patient' }
    focus_bundle = response_bundle_hash.merge(
      'entry' => response_bundle_hash['entry'].map do |entry|
        entry['resource']['resourceType'] == 'Patient' ? request_patient_entry : entry
      end
    )

    result = run_test(request_bundle, focus_bundle)

    expect(result.result).to eq('pass')
    expect(result_messages(result, 'error')).to be_empty
  end

  it 'reports a focus resource that is not a Bundle without validating it further' do
    result = run_test(request_bundle_hash, { resourceType: 'ClaimResponse', status: 'active' })

    expect(result.result).to eq('fail')
    expect(result_messages(result, 'error')).to contain_exactly(a_string_including('found `ClaimResponse`'))
  end
end
