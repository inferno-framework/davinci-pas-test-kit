require 'json'
require_relative '../../../lib/davinci_pas_test_kit/client/v2.2.1/urls'

# Guards the example "ms_submit_responses" candidates shipped in the "Run Against the PAS Server
# Suite" preset (config/presets/pas_client_v221_run_against_pas_server.json): this is the only
# shipped preset that demonstrates the must support response selection/notification feature
# (requestRange-based selection between multiple candidates, and a candidate's "notification" key
# triggering a Subscription event notification), so this spec keeps that demonstration working.
RSpec.describe DaVinciPASTestKit::AbstractGatherMustSupportTest, :request do
  describe 'the ms_submit_responses candidates in the pas_client_v221_run_against_pas_server.json preset' do
    let(:suite_id) { 'davinci_pas_client_suite_v221' }
    let(:session_url_path) { '1234' }
    let(:test) do
      Class.new(described_class) do
        include DaVinciPASTestKit::DaVinciPASV221::URLs

        def suite_id
          'davinci_pas_client_suite_v221'
        end
      end
    end
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:result) { repo_create(:result, test_session_id: test_session.id) }
    let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
    let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    let(:notification_endpoint) { 'https://subscriptions.argo.run/fhir/r4/$subscription-hook' }
    let(:submit_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
    end
    let(:subscription_create_response_full_resource) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
    end
    let(:preset_path) do
      File.join(__dir__, '../../..', 'config', 'presets', 'pas_client_v221_run_against_pas_server.json')
    end
    let(:ms_submit_responses) do
      JSON.parse(File.read(preset_path))['inputs'].find { |input| input['name'] == 'ms_submit_responses' }['value']
    end

    def create_subscription_request
      repo_create(
        :request,
        direction: 'incoming',
        url: subscription_url,
        test_session_id: test_session.id,
        result:,
        response_body: subscription_create_response_full_resource.to_json,
        tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
        status: 201
      )
    end

    # Request numbering (used by the requestRange criteria) relies on the URLs of previously
    # persisted requests, which are built from REQUEST_PATH. Puma sets it in production, but
    # Rack::Test does not, so it must be supplied explicitly for the persisted requests to be
    # countable - see the equivalent helper in claim_endpoint_spec.rb.
    def post_json_with_request_path(url, json)
      post(url, json.to_json, 'CONTENT_TYPE' => 'application/json', 'REQUEST_PATH' => url)
    end

    def returned_claim_response
      FHIR.from_contents(last_response.body).entry[0].resource
    end

    def review_action_extension(adjudication)
      review_action = adjudication.extension.find do |ext|
        ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'
      end
      review_action&.extension&.find do |ext|
        ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'
      end
    end

    def review_action_codes(claim_response)
      claim_response.item.flat_map do |item|
        item.adjudication.map do |adjudication|
          review_code = review_action_extension(adjudication)
          coding = review_code&.valueCodeableConcept&.coding
          coding&.first&.code
        end
      end.compact
    end

    def notification_requests(test_session_id)
      requests_repo.tagged_requests(test_session_id, [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
    end

    before do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification)
        .to receive(:rand).with(5..10).and_return(0)
    end

    it 'has more than one candidate, so the requestRange criteria has something to select between' do
      expect(JSON.parse(ms_submit_responses).length).to be > 1
    end

    it 'returns the first (approval) candidate, without a notification, for the first request' do
      create_subscription_request
      inputs = { session_url_path:, ms_submit_responses: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json_with_request_path(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(review_action_codes(returned_claim_response)).to all(eq('A1'))
      expect(notification_requests(result.test_session_id)).to be_empty
    end

    it 'returns the second (pended) candidate and sends a notification from the second request on' do
      create_subscription_request
      inputs = { session_url_path:, ms_submit_responses: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json_with_request_path(submit_url, submit_request_json) # 1st request: approval candidate

      notification_request = stub_request(:post, notification_endpoint).to_return(status: 200)
      post_json_with_request_path(submit_url, submit_request_json) # 2nd request: pended candidate

      expect(last_response.status).to be(200)
      expect(review_action_codes(returned_claim_response)).to all(eq('A4'))
      expect(notification_request).to have_been_made.times(1)
      expect(notification_requests(result.test_session_id).length).to eq(1)
    end
  end
end
