RSpec.describe DaVinciPASTestKit::DaVinciPASV201::SubscriptionPASConformanceTest, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }

  describe 'responding to requests from the client under tests' do
    let(:access_token) { '1234' }
    let(:static_uuid) { 'f015a331-3a86-4566-b72f-b5b85902cdca' }
    let(:test) { described_class }
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
end
