require_relative '../../../lib/davinci_pas_test_kit/client/subscription_notification_trigger'

RSpec.describe DaVinciPASTestKit::SubscriptionNotificationTrigger do
  # Stands in for a class such as an Inferno test that reads its inputs and earlier requests its own way
  let(:host_class) do
    Class.new do
      include DaVinciPASTestKit::SubscriptionNotificationTrigger

      attr_accessor :tester_notification, :subscription

      def notification_test_run_id = 'run-1'
      def notification_test_session_id = 'session-1'
      def notification_result_id = 'result-1'
      def notification_bearer_token = 'token-1'
      def tester_notification_bundle = tester_notification
      def client_subscription_json = subscription
      def test_run_identifier = 'resume-1'
      def suite_id = 'davinci_pas_client_suite_v221'
      def ig_version = 'v2.2.1'
      def fhir_subscription_url = 'http://example.org/fhir/Subscription'
    end
  end
  let(:host) { host_class.new }
  let(:payload_extension_url) do
    'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content'
  end
  let(:subscription_json) do
    { 'resourceType' => 'Subscription', 'id' => 'sub-1', 'criteria' => 'http://example.org/topic',
      'channel' => { 'type' => 'rest-hook', 'endpoint' => 'https://client.example.org/notify' } }
  end
  let(:full_resource_subscription_json) do
    subscription_json.deep_merge('channel' => { '_payload' => { 'extension' => [{ 'url' => payload_extension_url,
                                                                                  'valueCode' => 'full-resource' }] } })
  end
  let(:response_bundle_json) do
    { resourceType: 'Bundle', type: 'collection',
      entry: [{ fullUrl: 'urn:uuid:cr-1',
                resource: { resourceType: 'ClaimResponse', id: 'cr-1', status: 'active', use: 'preauthorization',
                            outcome: 'queued', created: '2024-01-01T00:00:00Z' } }] }.to_json
  end
  let(:tester_notification_json) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_example_id_only.json'))
  end

  def started_job_args
    captured = nil
    allow(Inferno::Jobs).to receive(:perform) { |*args| captured = args }
    yield
    captured
  end

  def notification_in(args)
    FHIR.from_contents(args[5])
  end

  before { host.subscription = subscription_json }

  it 'starts the notification job with the values the including class provides' do
    args = started_job_args { host.start_notification_job(response_bundle_json, :approval, 'cr-1') }

    job, run_id, session_id, result_id, token, _notification, resume_token, suite_id, ig_version, resume_test = args
    expect(job).to eq(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification)
    expect([run_id, session_id, result_id, token]).to eq(%w[run-1 session-1 result-1 token-1])
    expect([resume_token, suite_id, ig_version]).to eq(%w[resume-1 davinci_pas_client_suite_v221 v2.2.1])
    expect(resume_test).to be(false)
  end

  it 'asks the job to end the wait when resume_test is set' do
    args = started_job_args do
      host.start_notification_job(response_bundle_json, :approval, 'cr-1', resume_test: true)
    end

    expect(args.last).to be(true)
  end

  describe 'when the tester provides a notification' do
    before { host.tester_notification = tester_notification_json }

    it 'sends the tester-provided notification, updated to be current' do
      args = started_job_args { host.start_notification_job(response_bundle_json, :approval, 'cr-1') }

      notification = notification_in(args)
      expect(notification).to be_a(FHIR::Bundle)
      expect(notification.timestamp).to_not eq(FHIR.from_contents(tester_notification_json).timestamp)
    end
  end

  describe 'when the tester does not provide a notification' do
    it 'mocks an id-only notification when the Subscription does not ask for full resources' do
      args = started_job_args { host.start_notification_job(response_bundle_json, :approval, 'cr-1') }

      notification = notification_in(args)
      expect(notification).to be_a(FHIR::Bundle)
      expect(notification.entry.map { |e| e.resource.resourceType }).to eq(['Parameters'])
    end

    it 'mocks a full-resource notification when the Subscription asks for full resources' do
      host.subscription = full_resource_subscription_json
      args = started_job_args { host.start_notification_job(response_bundle_json, :approval, 'cr-1') }

      resource_types = notification_in(args).entry.map { |e| e.resource.resourceType }
      expect(resource_types).to include('Parameters', 'Bundle')
    end
  end

  it 'requires the including class to provide the helper methods' do
    bare_host = Class.new { include DaVinciPASTestKit::SubscriptionNotificationTrigger }.new

    expect { bare_host.notification_result_id }.to raise_error(NotImplementedError, /notification_result_id/)
  end
end
