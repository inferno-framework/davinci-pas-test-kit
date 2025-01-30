RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientSubscriptionCreateTest, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }

  describe 'when responding to requests from the client under tests' do
    let(:access_token) { '1234' }
    let(:test) { described_class }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:result) { repo_create(:result, test_session_id: test_session.id) }
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:subscription_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    let(:subscription_create_response_full_resource) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
    end
    let(:notification_json_bundle) do
      File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_example_full_resource.json'))
    end

    it 'remains in wait status when a Subscription Creation request received' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(subscription_url, subscription_create_response_full_resource)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns HTTP status 201 CREATED for a Subscription Create request' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(subscription_url, subscription_create_response_full_resource)

      expect(last_response.status).to be(201)
    end

    it 'returns 400 when the subscription is invalid' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(subscription_url, notification_json_bundle)

      expect(last_response.status).to be(400)
    end

    it 'returns 400 for a second subscription creation request' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(subscription_url, subscription_create_response_full_resource)
      post_json(subscription_url, subscription_create_response_full_resource)

      expect(last_response.status).to be(400)
    end

    it 'tags subscription creation requests' do
      allow_any_instance_of(DaVinciPASTestKit::Jobs::SendSubscriptionHandshake) # skip handshake
        .to receive(:perform).and_return(nil)

      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
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

      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
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
            'Authorization' => "Bearer #{access_token}"
          }
        )
        .to_return(status: 200)
      continue_pass_request = stub_request(:get, 'http://example.org/custom/davinci_pas_client_suite_v201/resume_pass?token=1234')
        .to_return(status: 200) # look for request, not status update

      inputs = { access_token:, client_endpoint_access_token: access_token }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(subscription_url, subscription_create_response_full_resource)

      expect(handshake_request).to have_been_made.once
      expect(continue_pass_request).to have_been_made.once
    end

    describe 'triggering a handshake' do
      def create_subscription_request
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
          response_body: subscription_create_response_full_resource.to_json,
          tags: [DaVinciPASTestKit::SUBSCRIPTION_CREATE_TAG],
          status: 201,
          headers:
        )
      end

      it 'causes a pass if successful' do
        inputs = { access_token: }
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
          access_token,
          'http://example.com/'
        )
        expect(handshake_request).to have_been_made.times(1)
        expect(continue_pass_request).to have_been_made.times(1)
      end

      it 'causes a pass if unsuccessful' do
        # NOTE: failure checked later, and failure here didn't have
        # any context to say why there was a failure
        inputs = { access_token: }
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
          access_token,
          'http://example.com/'
        )
        expect(handshake_request).to have_been_made.times(1)
        expect(continue_pass_request).to have_been_made.times(1)
      end
    end
  end
end
