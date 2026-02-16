RSpec.describe DaVinciPASTestKit::SubscriptionPASConformanceTest, :request do
  describe 'v2.0.1 subscription verification' do
    let(:suite_id) { 'davinci_pas_client_suite_v201' }
    let(:access_token) { '1234' }
    let(:static_uuid) { 'f015a331-3a86-4566-b72f-b5b85902cdca' }
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            ig_version: 'v2.0.1'
          }
        )
      end
    end
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:result) { repo_create(:result, test_session_id: test_session.id) }
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:subscription_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    let(:subscription_create_request_full_resource) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
    end
    let(:bad_subscription_create_request) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures',
                                     'PAS_Subscription_example_bad_topic_and_criteria.json')))
    end

    def create_subscription_request(subscription)
      headers ||= [
        {
          type: 'request',
          name: 'Authorization',
          value: "Bearer #{access_token}"
        }
      ]
      repo_create(
        :request,
        direction: 'incoming',
        url: subscription_url,
        test_session_id: test_session.id,
        result:,
        request_body: subscription.to_json,
        tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
        status: 201,
        headers:
      )
    end

    it 'passes when conformant' do
      create_subscription_request(subscription_create_request_full_resource)
      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'skips when no Subscription Creation requests' do
      result = run(test)
      expect(result.result).to eq('skip')
    end

    it 'fails when not conformant' do
      create_subscription_request(bad_subscription_create_request)
      result = run(test)
      expect(result.result).to eq('fail')

      result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
      expect(result_messages.length).to be(2)
      result_messages.each do |message|
        expect(message.type).to eq('error')
      end
      expect(result_messages.find do |message|
               /must use the PAS-defined Subscription/.match(message.message)
             end).to_not be_nil
      expect(result_messages.find do |message|
               /must include a single filter on the submitting organization/.match(message.message)
             end).to_not be_nil
    end
  end

  describe 'v2.2.0 subscription verification' do
    let(:suite_id) { 'davinci_pas_client_suite_v201' }
    let(:access_token) { '1234' }
    let(:static_uuid) { 'f015a331-3a86-4566-b72f-b5b85902cdca' }
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            ig_version: 'v2.2.0'
          }
        )
      end
    end
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:result) { repo_create(:result, test_session_id: test_session.id) }
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:subscription_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    let(:good_v220_subscription) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_Subscription_example_v220_good.json')))
    end
    let(:bad_v220_subscription) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_Subscription_example_v220_bad.json')))
    end

    def create_subscription_request(subscription)
      headers ||= [
        {
          type: 'request',
          name: 'Authorization',
          value: "Bearer #{access_token}"
        }
      ]
      repo_create(
        :request,
        direction: 'incoming',
        url: subscription_url,
        test_session_id: test_session.id,
        result:,
        request_body: subscription.to_json,
        tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
        status: 201,
        headers:
      )
    end

    it 'passes with a valid v2.2.0 subscription' do
      create_subscription_request(good_v220_subscription)
      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'skips when no Subscription Creation requests' do
      result = run(test)
      expect(result.result).to eq('skip')
    end

    it 'fails with missing PAS profile, wrong channel type, and id-only payload' do
      create_subscription_request(bad_v220_subscription)
      result = run(test)
      expect(result.result).to eq('fail')

      result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
      error_messages = result_messages.select { |m| m.type == 'error' }
      expect(error_messages.length).to be >= 3

      expect(error_messages.find do |message|
               /must declare conformance to the PAS Subscription profile/.match(message.message)
             end).to_not be_nil
      expect(error_messages.find do |message|
               /channel type must be `rest-hook`/.match(message.message)
             end).to_not be_nil
      expect(error_messages.find do |message|
               /payload content type must be `full-resource`/.match(message.message)
             end).to_not be_nil
    end
  end
end
