require_relative '../../lib/davinci_pas_test_kit/pas_notification_conformance_test'

RSpec.describe DaVinciPASTestKit::NotificationPASConformanceTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:notification_body_good) do
    File.read(File.join(__dir__, '../fixtures', 'PAS_notification_example_full_resource.json'))
  end
  let(:notification_body_bad) do
    {
      resourceType: 'Bundle',
      type: 'subscription-notification',
      entry: [
        {
          fullUrl: 'urn:uuid:status',
          resource: {
            resourceType: 'Parameters',
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

  it 'passes when conformant with a PAS focus resource' do
    create_notification_request(notification_body_good)
    result = run(described_class)
    expect(result.result).to eq('pass')
  end

  it 'skips when no notification requests are found' do
    result = run(described_class)
    expect(result.result).to eq('skip')
  end

  it 'fails when no focus resource is present' do
    create_notification_request(notification_body_bad)
    result = run(described_class)
    expect(result.result).to eq('fail')

    result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
    expect(result_messages.any? do |m|
      m.message.include?('must include at least one focus resource entry')
    end).to be(true)
  end
end
