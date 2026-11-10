require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/must_support/' \
                 'pas_client_must_support_notification_tests'
require_relative '../../../support/custom_extension_validator_stub'
require_relative '../../../support/client_suite_test_lookup'

# Covers the three must support notification tests, which share MustSupportNotificationHelper. Described by one of
# them so that the runnable spec helpers are available.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientMustSupportNotificationAcceptanceTest, :request do
  include ClientSuiteTestLookup

  include_context 'with custom extension validator stub'

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  # Requests share a result: Inferno only loads tagged requests from the latest result of each runnable, and
  # results created here have no runnable
  let(:gather_result) { repo_create(:result, test_session_id: test_session.id) }
  let(:generator) { Class.new { include DaVinciPASTestKit::ResponseGenerator }.new }
  let(:request_bundle_hash) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end
  let(:request_bundle) { FHIR.from_contents(request_bundle_hash.to_json) }
  let(:subscription_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_v221_good.json')))
      .merge('id' => 'sub-1')
  end
  let(:subscription_reference) { 'http://example.com/fhir/Subscription/sub-1' }

  def suite_test(id)
    v221_client_suite_test(:pas_client_v221_must_support_no_auth, :pas_client_v221_must_support_receive, id)
  end

  def response_json(decision, claim_response_id)
    generator.mock_response_bundle(request_bundle, 'submit', decision, claim_response_id, 'v2.2.1')
  end

  def notification_json(response)
    generator.mock_full_resource_notification_bundle(response, subscription_reference, subscription_json['criteria'],
                                                     :approval, 'v2.2.1')
  end

  def create_submit_request(response, link_id)
    repo_create(:request, direction: 'incoming', url: "/custom/#{suite_id}/#{session_url_path}/fhir/Claim/$submit",
                          test_session_id: test_session.id, result: gather_result,
                          request_body: request_bundle_hash.to_json, response_body: response, status: 200,
                          tags: [DaVinciPASTestKit::SUBMIT_TAG, DaVinciPASTestKit::MUST_SUPPORT_WORKFLOW_TAG,
                                 DaVinciPASTestKit.notification_link_tag(link_id)])
  end

  def create_notification(body, link_id, status: 200)
    repo_create(:request, direction: 'outgoing', url: 'http://client.example.com/notify',
                          test_session_id: test_session.id, result: gather_result, request_body: body, status:,
                          response_body: '', tags: [DaVinciPASTestKit::MUST_SUPPORT_NOTIFICATION_TAG,
                                                    DaVinciPASTestKit.notification_link_tag(link_id)])
  end

  def create_subscription_request
    repo_create(:request, direction: 'incoming', url: "/custom/#{suite_id}/#{session_url_path}/fhir/Subscription",
                          test_session_id: test_session.id, result: gather_result,
                          response_body: subscription_json.to_json, status: 201,
                          tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG])
  end

  # An approved request followed by a pended one with its notification, so that the pended request is $submit
  # request 2
  def create_pended_exchange(notification: nil, notification_status: 200)
    create_submit_request(response_json(:approval, 'approved-cr'), 'approved')
    pended_response = response_json(:pended, 'pended-cr')
    create_submit_request(pended_response, 'pended')
    create_notification(notification || notification_json(pended_response), 'pended', status: notification_status)
  end

  def with_custom_extension_on_claim_response(notification)
    notification_hash = JSON.parse(notification)
    focus_bundle = notification_hash['entry'][1]['resource']
    claim_response = focus_bundle['entry'].find { |entry| entry['resource']['resourceType'] == 'ClaimResponse' }
    claim_response['resource']['extension'] = [custom_extension]
    notification_hash.to_json
  end

  def result_messages(result, type)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |m| m.type == type }.map(&:message)
  end

  describe 'the acceptance test' do
    let(:test) { suite_test(:pas_client_v221_ms_notification_acceptance_test) }

    it 'omits when Inferno returned no pended responses' do
      create_submit_request(response_json(:approval, 'approved-cr'), 'approved')

      result = run(test)

      expect(result.result).to eq('omit')
    end

    it 'skips when a pended response has no notification, naming the request' do
      create_submit_request(response_json(:approval, 'approved-cr'), 'approved')
      create_submit_request(response_json(:pended, 'pended-cr'), 'pended')

      result = run(test)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('after the pended response to $submit request(s) 2')
    end

    it 'passes when the PAS client accepted every notification' do
      create_pended_exchange

      expect(run(test).result).to eq('pass')
    end

    it 'fails, naming the request, when the notification request failed outright' do
      create_pended_exchange(notification_status: nil)

      result = run(test)

      expect(result.result).to eq('fail')
      expect(result_messages(result, 'error'))
        .to contain_exactly(a_string_starting_with('Notification for $submit request 2: the request failed'))
    end

    it 'fails, naming the request, when the PAS client rejected a notification' do
      create_pended_exchange(notification_status: 500)

      result = run(test)

      expect(result.result).to eq('fail')
      expect(result_messages(result, 'error'))
        .to eq(['Notification for $submit request 2: the PAS client responded with status code 500.'])
    end
  end

  describe 'the PAS conformance test' do
    let(:test) { suite_test(:pas_client_v221_ms_notification_pas_conformance_test) }

    it 'passes a notification that corresponds to the pended response' do
      create_pended_exchange

      result = run(test)

      expect(result.result).to eq('pass')
      expect(result_messages(result, 'warning')).to be_empty
    end

    it 'fails, naming the request, when the focus Bundle has a custom extension' do
      pended_response = response_json(:pended, 'pended-cr')
      create_pended_exchange(notification: with_custom_extension_on_claim_response(notification_json(pended_response)))

      result = run(test)

      expect(result.result).to eq('fail')
      expect(result_messages(result, 'error')).to include(
        a_string_starting_with('Notification for $submit request 2: Focus Bundle')
          .and(a_string_including("The extension #{custom_extension_url} could not be found"))
      )
    end

    it 'passes without a warning when the ClaimResponses share an identifier but not an id' do
      # Inferno's mocked ClaimResponses copy the identifiers of the Claim they answer
      create_pended_exchange(notification: notification_json(response_json(:pended, 'other-cr')))

      result = run(test)

      expect(result.result).to eq('pass')
      expect(result_messages(result, 'warning')).to be_empty
    end

    it 'warns when the notification is about a different ClaimResponse than the pended response' do
      notification = JSON.parse(notification_json(response_json(:pended, 'other-cr')))
      claim_response = notification['entry'][1]['resource']['entry']
        .find { |entry| entry['resource']['resourceType'] == 'ClaimResponse' }['resource']
      claim_response['identifier'] = [{ 'system' => 'http://example.org/other', 'value' => 'other' }]
      create_pended_exchange(notification: notification.to_json)

      result = run(test)

      expect(result.result).to eq('pass')
      expect(result_messages(result, 'warning')).to contain_exactly(
        a_string_starting_with('Notification for $submit request 2: ').and(a_string_including('`other-cr`'))
      )
    end

    it 'reports a notification too malformed to check and goes on to check the others' do
      create_submit_request(response_json(:pended, 'first-cr'), 'first')
      create_notification('not json', 'first')
      pended_response = response_json(:pended, 'second-cr')
      create_submit_request(pended_response, 'second')
      create_notification(with_custom_extension_on_claim_response(notification_json(pended_response)), 'second')

      result = run(test)

      errors = result_messages(result, 'error')
      expect(errors).to include(a_string_starting_with('Notification for $submit request 1: '))
      expect(errors).to include(a_string_starting_with('Notification for $submit request 2: Focus Bundle'))
    end
  end

  describe 'the Subscriptions conformance test' do
    let(:test) { suite_test(:pas_client_v221_ms_notification_conformance_test) }

    it 'omits rather than requiring a Subscription when Inferno returned no pended responses' do
      create_submit_request(response_json(:approval, 'approved-cr'), 'approved')

      expect(run(test).result).to eq('omit')
    end

    it 'skips when there is no Subscription to check the payload content against' do
      create_pended_exchange

      result = run(test)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('There is no Subscription')
    end
  end

  describe 'the Subscriptions conformance test with a Subscription' do
    let(:test) { suite_test(:pas_client_v221_ms_notification_conformance_test) }

    before { create_subscription_request }

    it 'passes a notification mocked by Inferno, checking its payload content' do
      create_pended_exchange

      result = run(test)

      expect(result.result).to eq('pass')
      expect(result_messages(result, 'warning')).to be_empty
    end

    it 'reports a notification the checks cannot handle and goes on to check the others' do
      first_response = response_json(:pended, 'first-cr')
      create_submit_request(first_response, 'first')
      malformed = JSON.parse(notification_json(first_response))
      malformed['entry'][0]['resource']['parameter'].reject! { |param| param['name'] == 'type' }
      create_notification(malformed.to_json, 'first')
      second_response = response_json(:pended, 'second-cr')
      create_submit_request(second_response, 'second')
      second = JSON.parse(notification_json(second_response))
      second['entry'][0]['resource']['extension'] = [custom_extension]
      create_notification(second.to_json, 'second')

      result = run(test)

      errors = result_messages(result, 'error')
      expect(errors).to include(a_string_starting_with('Notification for $submit request 1: '))
      expect(errors).to include(a_string_starting_with('Notification for $submit request 2: ')
                                  .and(a_string_including(custom_extension_url)))
    end

    it 'fails, naming the request, when the SubscriptionStatus has a custom extension' do
      pended_response = response_json(:pended, 'pended-cr')
      notification = JSON.parse(notification_json(pended_response))
      notification['entry'][0]['resource']['extension'] = [custom_extension]
      create_pended_exchange(notification: notification.to_json)

      result = run(test)

      expect(result.result).to eq('fail')
      expect(result_messages(result, 'error')).to include(
        a_string_starting_with('Notification for $submit request 2: ')
          .and(a_string_including("The extension #{custom_extension_url} could not be found"))
      )
    end
  end
end
