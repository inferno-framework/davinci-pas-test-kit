require_relative '../../lib/davinci_pas_test_kit/pas_notification_conformance_test'

RSpec.describe DaVinciPASTestKit::NotificationPASConformanceTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:fhirpath_url) { 'https://example.com/fhirpath/evaluate' }
  let(:operation_outcome_success) do
    {
      outcomes: [{
        issues: []
      }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
    }
  end
  let(:pas_response_bundle) do
    JSON.parse(File.read(File.join(__dir__, '../fixtures', 'valid_pa_response_bundle.json')))
  end
  let(:test) do
    Class.new(described_class) do
      fhir_resource_validator do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')

        cli_context do
          txServer nil
          displayWarnings true
          disableDefaultResourceFetcher true
        end

        igs('hl7.fhir.us.davinci-pas#2.0.1')
      end
    end
  end
  let(:notification_body_good) do
    {
      resourceType: 'Bundle',
      type: 'history',
      timestamp: '2024-01-30T13:44:30Z',
      meta: {
        profile: [
          'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-subscription-notification-r4'
        ]
      },
      entry: [
        {
          fullUrl: 'urn:uuid:status-entry',
          resource: {
            resourceType: 'Parameters',
            id: 'status-entry',
            parameter: [
              { name: 'subscription', valueReference: { reference: 'Subscription/123' } },
              { name: 'status', valueCode: 'active' },
              { name: 'type', valueCode: 'event-notification' },
              {
                name: 'notification-event',
                part: [
                  { name: 'event-number', valueString: '1' },
                  { name: 'focus', valueReference: { reference: 'urn:uuid:focus-bundle' } }
                ]
              }
            ]
          },
          request: { method: 'GET', url: 'Subscription/123/$status' },
          response: { status: '200' }
        },
        {
          fullUrl: 'urn:uuid:focus-bundle',
          resource: pas_response_bundle
        }
      ]
    }.to_json
  end
  let(:notification_body_no_focus) do
    {
      resourceType: 'Bundle',
      type: 'history',
      entry: [
        {
          fullUrl: 'urn:uuid:status-entry',
          resource: {
            resourceType: 'Parameters',
            id: 'status-entry',
            parameter: [
              { name: 'subscription', valueReference: { reference: 'Subscription/123' } },
              { name: 'notification-event',
                part: [
                  { name: 'event-number', valueString: '1' }
                ] }
            ]
          }
        }
      ]
    }.to_json
  end
  let(:notification_body_no_notification_event) do
    {
      resourceType: 'Bundle',
      type: 'history',
      entry: [
        {
          fullUrl: 'urn:uuid:status-entry',
          resource: {
            resourceType: 'Parameters',
            id: 'status-entry',
            parameter: [
              { name: 'subscription', valueReference: { reference: 'Subscription/123' } }
            ]
          }
        }
      ]
    }.to_json
  end

  def create_notification_request(body)
    repo_create(
      :request,
      direction: 'incoming',
      url: 'http://example.com/notification',
      test_session_id: test_session.id,
      result:,
      request_body: body,
      tags: [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG],
      status: 200
    )
  end

  it 'passes when focus resource is a valid PAS Response Bundle' do
    stub_request(:post, validation_url)
      .to_return(status: 200, body: operation_outcome_success.to_json)
    stub_request(:post, /#{fhirpath_url}/)
      .to_return(status: 200, body: [].to_json)

    create_notification_request(notification_body_good)
    result = run(test)
    expect(result.result).to eq('pass')
  end

  it 'skips when no notification requests are found' do
    result = run(test)
    expect(result.result).to eq('skip')
  end

  it 'fails when no notification-event focus reference is present' do
    create_notification_request(notification_body_no_focus)
    result = run(test)
    expect(result.result).to eq('fail')
    expect(result.result_message).to include('focus reference')
  end

  it 'fails when no notification-event parameter is present' do
    create_notification_request(notification_body_no_notification_event)
    result = run(test)
    expect(result.result).to eq('fail')
    expect(result.result_message).to include('notification-event')
  end
end
