require_relative '../../../../lib/davinci_pas_test_kit/client/jobs/send_pas_subscription_notification'

RSpec.describe DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:client_endpoint) { 'https://client.example.org/notify' }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_v221_good.json')))
      .merge('id' => 'sub-1').tap { |subscription| subscription['channel']['endpoint'] = client_endpoint }
  end
  let(:notification_json) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_full_resource.json'))
  end
  let(:job) { described_class.new }

  def create_request(tags, response_body: nil, status: 200)
    repo_create(:request, direction: 'outgoing', url: client_endpoint, test_session_id: test_session.id, result:,
                          response_body:, status:, tags:)
  end

  def perform_job(tags)
    job.perform(nil, test_session.id, result.id, nil, notification_json, 'resume-token', suite_id, 'v2.2.1', false,
                tags)
  end

  def subscription_status(request)
    FHIR.from_contents(request.request_body).entry.first.resource
  end

  def events_since_subscription_start(request)
    subscription_status(request).parameter.find { |param| param.name == 'events-since-subscription-start' }
      .valueString
  end

  def event_number(request)
    event = subscription_status(request).parameter.find { |param| param.name == 'notification-event' }
    event.part.find { |part| part.name == 'event-number' }.valueString
  end

  before do
    create_request([DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], response_body: subscription_json.to_json,
                                                                 status: 201)
    allow(job).to receive(:sleep)
    allow(job).to receive(:test_still_waiting?).and_return(true)
    stub_request(:post, client_endpoint).to_return(status: 200)
  end

  it 'records the notification with the given tags' do
    perform_job(%w[tag-a tag-b])

    expect(requests_repo.tagged_requests(test_session.id, %w[tag-a tag-b]).length).to eq(1)
    expect(requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG]))
      .to be_empty
  end

  it 'counts the event notifications already sent in the session, from either workflow' do
    create_request([DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
    create_request([DaVinciPASTestKit::MUST_SUPPORT_NOTIFICATION_TAG])

    perform_job([DaVinciPASTestKit::MUST_SUPPORT_NOTIFICATION_TAG, 'new'])

    notification = requests_repo.tagged_requests(test_session.id, ['new']).first
    expect(events_since_subscription_start(notification)).to eq('3')
    expect(event_number(notification)).to eq('3')
  end
end
