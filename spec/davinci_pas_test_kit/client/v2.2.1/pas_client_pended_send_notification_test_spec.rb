require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/urls'
require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/workflows/pas_client_pended_send_notification_test'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientPendedNotifyAndAttestFinalizedTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:job_class) { DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
  end
  let(:claim_response_uuid) { 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' }
  let(:pended_response_json) do
    { resourceType: 'Bundle', type: 'collection',
      entry: [{ fullUrl: "urn:uuid:#{claim_response_uuid}",
                resource: { resourceType: 'ClaimResponse', id: claim_response_uuid, status: 'active',
                            use: 'preauthorization', outcome: 'queued', created: '2024-01-01T00:00:00Z' } }] }.to_json
  end
  let(:tester_notification_json) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_id_only.json'))
  end

  # Only requests from the most recent result of a runnable are found by tag, so share one result
  let(:earlier_result) { repo_create(:result, test_session_id: test_session.id) }

  def create_request(tags:, status:, response_body:)
    repo_create(:request, direction: 'incoming', url: 'http://example.org/fhir', test_session_id: test_session.id,
                          result: earlier_result, status:, response_body:, tags:)
  end

  def create_subscription_request
    create_request(tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], status: 201,
                   response_body: subscription_json.to_json)
  end

  def create_pended_submit_request(status: 200)
    create_request(tags: [DaVinciPASTestKit::SUBMIT_TAG, DaVinciPASTestKit::PENDED_WORKFLOW_TAG], status:,
                   response_body: pended_response_json)
  end

  def run_capturing_job_args(inputs = {})
    captured = nil
    allow(Inferno::Jobs).to receive(:perform) { |*args| captured = args }
    result = run(described_class, inputs)
    [result, captured]
  end

  describe 'before sending the notification' do
    it 'skips when there is no Subscription' do
      create_pended_submit_request
      result = run(described_class)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('no Subscription exists to receive notifications')
    end

    it 'skips when there is no successful pended $submit request' do
      create_subscription_request
      create_pended_submit_request(status: 400)
      result = run(described_class)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('no successful $submit request')
    end

    it 'fails when the notification input is not valid JSON' do
      create_subscription_request
      create_pended_submit_request
      result = run(described_class, notification_bundle: 'not json')

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/must be valid JSON/i)
    end
  end

  describe 'sending the notification' do
    before do
      create_subscription_request
      create_pended_submit_request
    end

    it 'starts the notification job and waits for it to end the wait' do
      result, args = run_capturing_job_args

      expect(result.result).to eq('wait')
      job, run_id, session_id, result_id, _token, notification, resume_token, job_suite_id, ig_version,
        resume_test = args
      expect(job).to eq(job_class)
      expect([run_id, result_id]).to eq([nil, nil]) # looked up by the job once the test is waiting
      expect(session_id).to eq(test_session.id)
      # a fresh random identifier, not shared with any other wait in the session
      expect(resume_token).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      waiting_run = Inferno::Repositories::TestRuns.new.find_latest_waiting_by_identifier(resume_token)
      expect(waiting_run&.id).to eq(result.test_run_id)
      expect([job_suite_id, ig_version, resume_test]).to eq([suite_id, 'v2.2.1', true])
      expect(FHIR.from_contents(notification)).to be_a(FHIR::Bundle)
    end

    it 'sends the client notification access token' do
      _result, args = run_capturing_job_args(client_endpoint_access_token: 'client-token')

      expect(args[4]).to eq('client-token')
    end

    it 'sends a notification generated from the pended response by default' do
      _result, args = run_capturing_job_args
      notification = FHIR.from_contents(args[5])

      resource_types = notification.entry.map { |entry| entry.resource.resourceType }
      expect(resource_types).to include('Parameters', 'Bundle')
    end

    it 'sends the tester-provided notification, pointing it at the ClaimResponse Inferno generated' do
      _result, args = run_capturing_job_args(notification_bundle: tester_notification_json)
      focus_references = args[5].scan(/"reference"\s*:\s*"([^"]+)"/).flatten

      expect(FHIR.from_contents(args[5])).to be_a(FHIR::Bundle)
      expect(focus_references).to include("urn:uuid:#{claim_response_uuid}")
    end

    it 'leaves the tester-provided notification pointing where the tester set it when the tester ' \
       'provided the pended response' do
      _result, args = run_capturing_job_args(notification_bundle: tester_notification_json,
                                             pended_json_response: pended_response_json)

      expect(args[5]).to_not include("urn:uuid:#{claim_response_uuid}")
    end
  end

  describe 'the notification job started by the test' do
    let(:client_endpoint) { 'https://subscriptions.argo.run/fhir/r4/$subscription-hook' }

    # args[6] is the test's random wait identifier, which the job uses to end the wait
    def resume_url(path, args)
      "#{Inferno::Application['base_url']}/custom/#{suite_id}/#{path}?token=#{args[6]}"
    end

    before do
      create_subscription_request
      create_pended_submit_request
      allow_any_instance_of(job_class).to receive(:sleep)
    end

    def perform_job(args)
      job_class.new.perform(nil, test_session.id, nil, nil, args[5], args[6], suite_id, 'v2.2.1', true)
    end

    it 'sends the notification, records it on the waiting result and ends the wait' do
      result, args = run_capturing_job_args
      expect(result.result).to eq('wait')
      notification_request = stub_request(:post, client_endpoint).to_return(status: 200)
      resume_request = stub_request(:get, resume_url('resume_pass', args)).to_return(status: 200)

      perform_job(args)

      expect(notification_request).to have_been_made.once
      expect(resume_request).to have_been_made.once
      sent = requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
      expect(sent.length).to eq(1)
      expect(requests_repo.requests_for_result(result.id).map(&:id)).to include(sent.first.id)
    end

    it 'fails the wait when sending the notification raises an error' do
      _result, args = run_capturing_job_args
      allow_any_instance_of(job_class).to receive(:send_notification).and_raise(StandardError, 'boom')
      fail_request = stub_request(:get, resume_url('resume_fail', args)).to_return(status: 200)

      perform_job(args)

      expect(fail_request).to have_been_made.once
    end

    it 'does not send the notification when the test is no longer waiting' do
      result, args = run_capturing_job_args
      results_repo.update_result(result.id, 'skip')
      notification_request = stub_request(:post, client_endpoint).to_return(status: 200)

      perform_job(args)

      expect(notification_request).to_not have_been_made
    end

    it 'sends the notification when the test is slow to start waiting' do
      result, args = run_capturing_job_args
      notification_request = stub_request(:post, client_endpoint).to_return(status: 200)
      resume_request = stub_request(:get, resume_url('resume_pass', args)).to_return(status: 200)
      # not waiting for well past the old ~20 second limit, then waiting from then on
      allow_any_instance_of(job_class).to receive(:test_still_waiting?).and_return(*Array.new(100, false), true)

      perform_job(args)

      expect(notification_request).to have_been_made.once
      expect(resume_request).to have_been_made.once
      sent = requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
      expect(requests_repo.requests_for_result(result.id).map(&:id)).to include(sent.first.id)
    end

    it 'logs and gives up without sending or resuming when the test never starts waiting' do
      _result, args = run_capturing_job_args
      notification_request = stub_request(:post, client_endpoint).to_return(status: 200)
      allow_any_instance_of(job_class).to receive(:test_still_waiting?).and_return(false)
      allow(Inferno::Application['logger']).to receive(:error)

      perform_job(args)

      expect(notification_request).to_not have_been_made
      expect(Inferno::Application['logger']).to have_received(:error).with(/no test started waiting/)
    end
  end
end
