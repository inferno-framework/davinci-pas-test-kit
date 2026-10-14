RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientSubscriptionPutUpdatePASConformanceTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:test) { find_test(suite, described_class.id) }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:subscription_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
  let(:good_subscription) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_v221_good.json')))
  end
  let(:subscription_id) { good_subscription['id'] }
  let(:bad_subscription) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_v221_bad.json')))
      .merge('id' => subscription_id)
  end
  let(:validation_success) { { outcomes: [{ issues: [] }], sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2' } }
  let(:validation_failure) do
    { outcomes: [{ issues: [{ level: 'ERROR', message: 'Resource does not conform to profile' }] }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2' }
  end

  def create_subscription_request
    repo_create(:request, verb: 'POST', direction: 'incoming', url: subscription_url, test_session_id: test_session.id,
                          result:, request_body: good_subscription.except('id').to_json,
                          response_body: good_subscription.to_json,
                          tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG], status: 201)
  end

  def create_update_request(subscription, status: 200, verb: 'PUT', id: subscription_id)
    repo_create(:request, verb:, direction: 'incoming', url: "#{subscription_url}/#{id}",
                          test_session_id: test_session.id, result:, request_body: subscription.to_json,
                          response_body: subscription.to_json,
                          tags: [SubscriptionsTestKit::SUBSCRIPTION_UPDATE_TAG, id], status:)
  end

  def error_messages(result)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |message| message.type == 'error' }
  end

  it 'skips when no Subscription was created' do
    result = run(test)

    expect(result.result).to eq('skip')
  end

  describe 'when a Subscription was created' do
    before { create_subscription_request }

    it 'skips when no PUT update requests were received' do
      create_update_request(good_subscription, verb: 'PATCH')
      result = run(test)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('did not receive a PUT request')
    end

    it 'skips when no PUT update requests were accepted' do
      create_update_request(bad_subscription, status: 400)
      result = run(test)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('did not accept any PUT update requests')
    end

    it 'ignores PUT update requests for other Subscription ids' do
      create_update_request(bad_subscription.merge('id' => 'other-id'), id: 'other-id')
      result = run(test)

      expect(result.result).to eq('skip')
    end

    it 'passes when the updated Subscriptions are conformant' do
      stub_request(:post, validation_url).to_return(status: 200, body: validation_success.to_json)
      create_update_request(good_subscription)
      create_update_request(good_subscription.merge('reason' => 'updated reason'))
      result = run(test)

      expect(result.result).to eq('pass')
    end

    it 'fails when an updated Subscription is not conformant, identifying the request' do
      # requests are validated in order, so only the second is reported as not conforming to the profile
      stub_request(:post, validation_url).to_return(status: 200, body: validation_success.to_json).then
        .to_return(status: 200, body: validation_failure.to_json)
      create_update_request(good_subscription)
      create_update_request(bad_subscription)
      result = run(test)

      expect(result.result).to eq('fail')
      expect(result.result_message).to include('do not conform to PAS requirements')
      messages = error_messages(result)
      expect(messages.map(&:message)).to all(start_with('Request 2: '))
      expect(messages.map(&:message)).to include(a_string_matching(/does not conform to profile/))
      expect(messages.map(&:message)).to include(a_string_matching(/expected format\s+`org-identifier=/))
    end

    it 'does not check rejected PUT update requests, but keeps numbering them' do
      stub_request(:post, validation_url).to_return(status: 200, body: validation_failure.to_json)
      create_update_request(good_subscription, status: 400)
      create_update_request(bad_subscription)
      result = run(test)

      expect(result.result).to eq('fail')
      expect(error_messages(result).map(&:message)).to all(start_with('Request 2: '))
    end
  end
end
