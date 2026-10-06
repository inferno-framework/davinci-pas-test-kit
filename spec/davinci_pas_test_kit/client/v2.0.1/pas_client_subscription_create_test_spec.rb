require_relative '../../../../lib/davinci_pas_test_kit/client/v2.0.1/urls'

RSpec.describe DaVinciPASTestKit::AbstractSubscriptionCreateTest, :request do
  describe 'when responding to requests from the client systems' do
    let(:suite_id) { 'davinci_pas_client_suite_v201' }
    let(:session_url_path) { '1234' }
    let(:notification_access_token) { '1234' }
    let(:test) do
      Class.new(described_class) do
        include DaVinciPASTestKit::DaVinciPASV201::URLs

        def suite_id
          'davinci_pas_client_suite_v201'
        end
      end
    end
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:result) { repo_create(:result, test_session_id: test_session.id) }
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    let(:subscription_create_response_full_resource) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
    end
    let(:notification_json_bundle) do
      File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_full_resource.json'))
    end

    it 'remains in wait status when a Subscription Creation request received' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { session_url_path: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, subscription_create_response_full_resource)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns HTTP status 201 CREATED for a Subscription Create request' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { session_url_path: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, subscription_create_response_full_resource)

      expect(last_response.status).to be(201)
    end

    it 'returns 400 when the subscription is invalid' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { session_url_path: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, notification_json_bundle)

      expect(last_response.status).to be(400)
    end

    it 'returns 400 for a second subscription creation request' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { session_url_path: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, subscription_create_response_full_resource)
      post_json(subscription_url, subscription_create_response_full_resource)

      expect(last_response.status).to be(400)
    end

    it 'tags subscription creation requests' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { session_url_path: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, subscription_create_response_full_resource)

      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG])
      expect(requests.length).to be(1)
    end

    it 'triggers a handshake after Subscription Create requests' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake)
        .to receive(:await_subscription_creation).and_return(nil) # disable subscription verification
      handshake_request = stub_request(:post, 'https://subscriptions.argo.run/fhir/r4/$subscription-hook')
        .to_return(status: 200)
      continue_pass_request = stub_request(:get, 'http://example.org/custom/davinci_pas_client_suite_v201/resume_pass?token=1234')
        .to_return(status: 200) # look for request, not status update

      inputs = { session_url_path: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, subscription_create_response_full_resource)

      expect(handshake_request).to have_been_made.once
      expect(continue_pass_request).to have_been_made.once
    end

    it 'sends the client_endpoint_access_token on the handshake after Subscription Create requests' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake)
        .to receive(:await_subscription_creation).and_return(nil) # disable subscription verification
      handshake_request = stub_request(:post, 'https://subscriptions.argo.run/fhir/r4/$subscription-hook')
        .with(
          headers: {
            'Authorization' => "Bearer #{notification_access_token}"
          }
        )
        .to_return(status: 200)
      continue_pass_request = stub_request(:get, 'http://example.org/custom/davinci_pas_client_suite_v201/resume_pass?token=1234')
        .to_return(status: 200) # look for request, not status update

      inputs = { session_url_path:, client_endpoint_access_token: notification_access_token }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(subscription_url, subscription_create_response_full_resource)

      expect(handshake_request).to have_been_made.once
      expect(continue_pass_request).to have_been_made.once
    end

    describe 'requests authenticated with an access token' do
      let(:client_id) { 'subscription-create-client' }
      let(:token_subscription_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }

      def create_with_token(minutes_from_now)
        token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, minutes_from_now)
        header('Authorization', "Bearer #{token}")
        post_json(token_subscription_url, subscription_create_response_full_resource)
      end

      it 'tags the request when the token is valid' do
        allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
          .to receive(:perform).and_return(nil)
        result = run(test, client_id:)
        expect(result.result).to eq('wait')

        create_with_token(5)

        expect(last_response.status).to be(201)
        requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG])
        expect(requests.length).to be(1)
      end

      it 'returns 401 and assigns no tags when the token has expired' do
        expect_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake).to_not receive(:perform)
        result = run(test, client_id:)
        expect(result.result).to eq('wait')

        create_with_token(-5)

        expect(last_response.status).to be(401)
        requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG])
        expect(requests).to be_empty
        expect(results_repo.find(result.id).result).to eq('wait')
      end
    end

    describe 'triggering a handshake' do
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

      it 'causes a pass if successful' do
        inputs = { session_url_path: }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        create_subscription_request
        handshake_request = stub_request(:post, 'https://subscriptions.argo.run/fhir/r4/$subscription-hook')
          .to_return(status: 200)
        continue_pass_request = stub_request(:get, 'http://example.com/resume_pass?token=1234')
          .to_return(status: 200)

        DaVinciPASTestKit::Jobs::SendSubscriptionHandshake.new.perform(
          result.test_run_id,
          result.test_session_id,
          result.id,
          subscription_create_response_full_resource['id'],
          "#{subscription_url}/#{subscription_create_response_full_resource['id']}",
          'https://subscriptions.argo.run/fhir/r4/$subscription-hook',
          nil,
          notification_json_bundle,
          notification_access_token,
          'http://example.com/'
        )
        expect(handshake_request).to have_been_made.times(1)
        expect(continue_pass_request).to have_been_made.times(1)
      end

      it 'causes a pass if unsuccessful' do
        # NOTE: failure checked later, and failure here didn't have
        # any context to say why there was a failure
        inputs = { session_url_path: }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        create_subscription_request
        handshake_request = stub_request(:post, 'https://subscriptions.argo.run/fhir/r4/$subscription-hook')
          .to_return(status: 400)
        continue_pass_request = stub_request(:get, 'http://example.com/resume_pass?token=1234')
          .to_return(status: 200)

        DaVinciPASTestKit::Jobs::SendSubscriptionHandshake.new.perform(
          result.test_run_id,
          result.test_session_id,
          result.id,
          subscription_create_response_full_resource['id'],
          "#{subscription_url}/#{subscription_create_response_full_resource['id']}",
          'https://subscriptions.argo.run/fhir/r4/$subscription-hook',
          nil,
          notification_json_bundle,
          notification_access_token,
          'http://example.com/'
        )
        expect(handshake_request).to have_been_made.times(1)
        expect(continue_pass_request).to have_been_made.times(1)
      end
    end
  end
end
