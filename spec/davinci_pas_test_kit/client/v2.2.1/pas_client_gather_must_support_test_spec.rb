require_relative '../../../support/client_suite_test_lookup'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientGatherMustSupportTest, :request do
  include ClientSuiteTestLookup

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:test) do
    v221_client_suite_test(:pas_client_v221_must_support_no_auth, :pas_client_v221_must_support_receive,
                           described_class.id)
  end
  let(:subscription_result) { repo_create(:result, test_session_id: test_session.id) }
  let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}/fhir/Subscription" }
  let(:generator) { Class.new { include DaVinciPASTestKit::ResponseGenerator }.new }
  let(:request_bundle) do
    FHIR.from_contents(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:pended_response) do
    JSON.parse(generator.mock_response_bundle(request_bundle, 'submit', :pended, 'cr', 'v2.2.1'))
  end
  let(:approved_response) do
    JSON.parse(generator.mock_response_bundle(request_bundle, 'submit', :approval, 'cr', 'v2.2.1'))
  end

  # Requests for the Subscription share a result, as when they are made while one test waits
  def create_subscription_request(**attributes)
    repo_create(:request, direction: 'incoming', url: subscription_url, test_session_id: test_session.id,
                          result: subscription_result,
                          response_body: { resourceType: 'Subscription', id: 'sub-1' }.to_json,
                          tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], status: 201, **attributes)
  end

  describe 'when the tester provides pended $submit responses' do
    let(:responses) { [{ 'criteria' => { 'requestRange' => '2' }, 'bundle' => pended_response }].to_json }

    it 'skips before waiting when no Subscription was created' do
      result = run(test, session_url_path:, ms_submit_responses: responses)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('no Subscription exists to receive the notifications')
    end

    it 'skips before waiting when the PAS client deleted its Subscription' do
      create_subscription_request
      create_subscription_request(url: "#{subscription_url}/sub-1", response_body: nil, status: 204,
                                  tags: [DaVinciPASTestKit::SUBSCRIPTION_DELETE_TAG, 'sub-1'])

      result = run(test, session_url_path:, ms_submit_responses: responses)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('submitted update or delete requests for its')
    end

    it 'waits, describing the notifications it will send, when there is a Subscription' do
      create_subscription_request

      result = run(test, session_url_path:, ms_submit_responses: responses,
                         ms_submit_notifications: [{ 'resourceType' => 'Bundle' }].to_json)

      expect(result.result).to eq('wait')
      expect(result.result_message).to include("selected from the '**Must Support Notification Bundles**' input")
      expect(result.result_message).to include('wait at least 15 seconds after the last pended response')
      expect(result.result_message.lines.grep(/\A {4,}\S/)).to be_empty
    end

    it 'describes mocked notifications when no notifications are provided' do
      create_subscription_request

      result = run(test, session_url_path:, ms_submit_responses: responses)

      expect(result.result_message).to include('The notification will be mocked by Inferno from the pended response.')
    end
  end

  it 'waits without a Subscription when none of the responses are pended' do
    result = run(test, session_url_path:, ms_submit_responses: [approved_response].to_json)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include('so Inferno will not send notifications')
  end

  it 'waits without a Subscription when the responses input is not usable, leaving it to be reported later' do
    result = run(test, session_url_path:, ms_submit_responses: '{')

    expect(result.result).to eq('wait')
  end
end
