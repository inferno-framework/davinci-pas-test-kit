require_relative '../../../support/client_suite_test_lookup'

# Exercises the notifications ClaimEndpoint sends, while this test waits, after pended responses in the
# v2.2.1 must support workflow
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientGatherMustSupportTest, :request do
  include ClientSuiteTestLookup

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:test) do
    v221_client_suite_test(:pas_client_v221_must_support_no_auth, :pas_client_v221_must_support_receive,
                           :pas_client_v221_gather_must_support)
  end
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:submit_request_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_v221_good.json')))
      .merge('id' => 'sub-1')
  end
  let(:generator) { Class.new { include DaVinciPASTestKit::ResponseGenerator }.new }
  let(:request_bundle) { FHIR.from_contents(submit_request_json.to_json) }
  let(:pended_response) do
    JSON.parse(generator.mock_response_bundle(request_bundle, 'submit', :pended, 'pended-cr', 'v2.2.1'))
  end
  let(:approved_response) do
    JSON.parse(generator.mock_response_bundle(request_bundle, 'submit', :approval, 'approved-cr', 'v2.2.1'))
  end
  let(:notification_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_full_resource.json')))
  end
  let(:subscription_result) { repo_create(:result, test_session_id: test_session.id) }
  let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}/fhir/Subscription" }

  def notification_with_id(id)
    notification_json.merge('id' => id)
  end

  # Requests for the Subscription share a result, as when they are made while one test waits
  def create_subscription_request(**attributes)
    repo_create(:request, direction: 'incoming', url: subscription_url, test_session_id: test_session.id,
                          result: subscription_result,
                          response_body: subscription_json.to_json, tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
                          status: 201, **attributes)
  end

  # The arguments of each notification job started, which is stubbed so that nothing is sent
  def notification_jobs
    @notification_jobs ||= []
  end

  def stub_notification_jobs
    allow(Inferno::Jobs).to receive(:perform).and_call_original
    allow(Inferno::Jobs).to receive(:perform)
      .with(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification, any_args) { |*args| notification_jobs << args }
  end

  def run_gather_test(**inputs)
    result = run(test, session_url_path:, **inputs)
    expect(result.result).to eq('wait')
    result
  end

  def result_warnings(result)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |m| m.type == 'warning' }
      .map(&:message)
  end

  before { stub_notification_jobs }

  describe 'with a Subscription' do
    before { create_subscription_request }

    it 'sends the selected tester-provided notification after a pended response, linked to the request' do
      notifications = [
        { 'criteria' => { 'requestRange' => '2' }, 'bundle' => notification_with_id('second') },
        { 'criteria' => { 'requestRange' => '1' }, 'bundle' => notification_with_id('first') }
      ]
      run_gather_test(ms_submit_responses: [pended_response].to_json, ms_submit_notifications: notifications.to_json)

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to eq(200)
      expect(notification_jobs.length).to eq(1)
      job_args = notification_jobs.first
      expect(JSON.parse(job_args[5])['id']).to eq('first')
      tags = job_args.last
      expect(tags).to include(DaVinciPASTestKit::MUST_SUPPORT_NOTIFICATION_TAG,
                              DaVinciPASTestKit::MUST_SUPPORT_WORKFLOW_TAG)
      expect(tags).to_not include(DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG)

      link_tag = tags.find { |tag| tag.start_with?(DaVinciPASTestKit::NOTIFICATION_LINK_TAG_PREFIX) }
      expect(requests_repo.tagged_requests(test_session.id, [DaVinciPASTestKit::SUBMIT_TAG, link_tag]).length)
        .to eq(1)
    end

    it 'mocks the notification when no tester-provided notification matches the request' do
      notifications = [{ 'criteria' => { 'requestRange' => '2' }, 'bundle' => notification_with_id('second') }]
      run_gather_test(ms_submit_responses: [pended_response].to_json, ms_submit_notifications: notifications.to_json)

      post_json(submit_url, submit_request_json)

      expect(notification_jobs.length).to eq(1)
      notification = JSON.parse(notification_jobs.first[5])
      expect(notification['id']).to_not eq('second')
      expect(notification['entry'].first['resource']['resourceType']).to eq('Parameters')
    end

    it 'sends no notification after a response that is not pended' do
      run_gather_test(ms_submit_responses: [approved_response].to_json,
                      ms_submit_notifications: [notification_with_id('unused')].to_json)

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to eq(200)
      expect(notification_jobs).to be_empty
    end

    it 'mocks the notification with a warning when the notifications input is not usable' do
      result = run_gather_test(ms_submit_responses: [pended_response].to_json, ms_submit_notifications: '{')

      post_json(submit_url, submit_request_json)

      expect(notification_jobs.length).to eq(1)
      expect(result_warnings(result)).to include(
        a_string_including('Unable to select a tester-provided notification, so Inferno will generate a default ' \
                           "notification: The 'Must Support Notification Bundles' input is not valid JSON.")
      )
    end
  end

  it 'warns instead of sending a notification when the Subscription was deleted' do
    # The gather test skips up front when there is no usable Subscription, so this covers the PAS client
    # deleting it while the test waits
    create_subscription_request
    result = run_gather_test(ms_submit_responses: [pended_response].to_json)
    create_subscription_request(url: "#{subscription_url}/sub-1", response_body: nil, status: 204,
                                tags: [DaVinciPASTestKit::SUBSCRIPTION_DELETE_TAG, 'sub-1'])

    post_json(submit_url, submit_request_json)

    expect(last_response.status).to eq(200)
    expect(notification_jobs).to be_empty
    expect(result_warnings(result)).to include(a_string_including('did not send a notification'))
  end
end
