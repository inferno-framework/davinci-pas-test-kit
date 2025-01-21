RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientPendedSubmitTest, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }

  describe 'responding to requests from the client under tests' do
    let(:access_token) { '1234' }
    let(:static_uuid) { 'f015a331-3a86-4566-b72f-b5b85902cdca' }
    let(:test) { described_class }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:result) { repo_create(:result, test_session_id: test_session.id) }
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:subscription_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
    let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
    let(:inquire_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::INQUIRE_PATH}" }
    let(:continue_pass_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{access_token}" }
    let(:subscription_create_response_full_resource) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_Subscription_example_full_resource.json')))
    end
    let(:submit_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
    end

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

    it 'skips if no subscription' do
      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/\bno Subscription\b/)
    end

    it 'continues after a resume request' do
      create_subscription_request
      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      get continue_pass_url
      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    describe 'when receiving $submit requets' do
      it 'keeps waiting when a submit request received' do
        allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
          .to receive(:perform).and_return(nil)
        create_subscription_request
        inputs = { access_token: }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        header('Authorization', "Bearer #{access_token}")
        post_json(submit_url, submit_request_json)

        result = results_repo.find(result.id)
        expect(result.result).to eq('wait')
      end

      it 'adds submit and pended tags' do
        allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
          .to receive(:perform).and_return(nil)
        create_subscription_request
        inputs = { access_token: }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        header('Authorization', "Bearer #{access_token}")
        post_json(submit_url, submit_request_json)

        requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                          DaVinciPASTestKit::PENDED_WORKFLOW_TAG])
        expect(requests.length).to be(1)
      end

      describe 'and the tester does not provide a submit response body' do
        it 'generates a pended response body' do
          allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
            .to receive(:perform).and_return(nil)
          create_subscription_request
          inputs = { access_token: }
          result = run(test, inputs)
          expect(result.result).to eq('wait')

          allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
          header('Authorization', "Bearer #{access_token}")
          post_json(submit_url, submit_request_json)
          fhir_body = FHIR.from_contents(last_response.body)
          expect(fhir_body).to be_a(FHIR::Bundle)
          expect(fhir_body.entry.length).to be >= 1
          expect(fhir_body.entry[0].resource).to be_a(FHIR::ClaimResponse)
          expect(fhir_body.entry[0].resource.id).to eq(static_uuid)
          fhir_body.entry[0].resource.adjudication.each do |item|
            review_action = item.extension.find do |ext|
              ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'
            end
            expect(review_action).to_not be_nil
            review_action_code = review_action.extension.find do |ext|
              ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'
            end
            expect(review_action_code).to_not be_nil
            expect(review_action_code.valueCodeableConcept&.coding&.dig(0)&.code).to eq('A4')
          end
        end
      end

      describe 'and the tester provides a submit response body' do
        let(:pended_response_json) do
          File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
        end

        it 'echoes the response body' do
          allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
            .to receive(:perform).and_return(nil)
          create_subscription_request
          inputs = { access_token:, pended_json_response: pended_response_json }
          result = run(test, inputs)
          expect(result.result).to eq('wait')

          allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
          header('Authorization', "Bearer #{access_token}")
          post_json(submit_url, submit_request_json)
          fhir_body = FHIR.from_contents(last_response.body)
          expect(fhir_body).to be_a(FHIR::Bundle)
          expect(fhir_body.entry.length).to be >= 1
          expect(fhir_body.entry[0].resource).to be_a(FHIR::ClaimResponse)
          expect(fhir_body.entry[0].resource.id).to eq(FHIR.from_contents(pended_response_json).entry[0].resource.id)
        end
      end
    end

    describe 'when receiving $inquire requets' do
      it 'keeps waiting' do
        create_subscription_request
        inputs = { access_token: }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        header('Authorization', "Bearer #{access_token}")
        post_json(inquire_url, submit_request_json)

        result = results_repo.find(result.id)
        expect(result.result).to eq('wait')
      end

      it 'adds inquire and pended tags' do
        create_subscription_request
        inputs = { access_token: }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        header('Authorization', "Bearer #{access_token}")
        post_json(inquire_url, submit_request_json)

        requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::INQUIRE_TAG,
                                                                          DaVinciPASTestKit::PENDED_WORKFLOW_TAG])
        expect(requests.length).to be(1)
      end

      describe 'and the tester does not provide an inquire response body' do
        it 'generates an approved response body' do
          create_subscription_request
          inputs = { access_token: }
          result = run(test, inputs)
          expect(result.result).to eq('wait')

          allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
          header('Authorization', "Bearer #{access_token}")
          post_json(inquire_url, submit_request_json)
          fhir_body = FHIR.from_contents(last_response.body)
          expect(fhir_body).to be_a(FHIR::Bundle)
          expect(fhir_body.entry.length).to be >= 1
          expect(fhir_body.entry[0].resource).to be_a(FHIR::ClaimResponse)
          expect(fhir_body.entry[0].resource.id).to eq(static_uuid)
          fhir_body.entry[0].resource.adjudication.each do |item|
            review_action = item.extension.find do |ext|
              ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'
            end
            expect(review_action).to_not be_nil
            review_action_code = review_action.extension.find do |ext|
              ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'
            end
            expect(review_action_code).to_not be_nil
            expect(review_action_code.valueCodeableConcept&.coding&.dig(0)&.code).to eq('A1')
          end
        end
      end

      describe 'and the tester provides an inquire response body' do
        let(:approval_response_json) do
          File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
        end

        it 'echoes the response body' do
          allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
            .to receive(:perform).and_return(nil)
          create_subscription_request
          inputs = { access_token:, inquire_json_response: approval_response_json }
          result = run(test, inputs)
          expect(result.result).to eq('wait')

          allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
          header('Authorization', "Bearer #{access_token}")
          post_json(inquire_url, submit_request_json)
          fhir_body = FHIR.from_contents(last_response.body)
          expect(fhir_body).to be_a(FHIR::Bundle)
          expect(fhir_body.entry.length).to be >= 1
          expect(fhir_body.entry[0].resource).to be_a(FHIR::ClaimResponse)
          expect(fhir_body.entry[0].resource.id).to eq(FHIR.from_contents(approval_response_json).entry[0].resource.id)
        end
      end
    end

    describe 'when sending notifications' do
      describe 'and the tester does not provide a notification body' do
        it 'generates a notification' do
          create_subscription_request
          inputs = { access_token: }
          result = run(test, inputs)
          expect(result.result).to eq('wait')

          notification_request = stub_request(:post, 'https://subscriptions.argo.run/fhir/r4/$subscription-hook')
            .to_return(status: 200)

          allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
          allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
            .to receive(:rand).with(5..10).and_return(0)
          header('Authorization', "Bearer #{access_token}")
          post_json(submit_url, submit_request_json)

          expect(notification_request).to have_been_made.times(1)
          notifications = requests_repo.tagged_requests(result.test_session_id,
                                                        [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
          expect(notifications.length).to be(1)
          fhir_body = FHIR.from_contents(notifications[0].request_body)
          expect(fhir_body).to be_a(FHIR::Bundle)
          expect(fhir_body.id).to eq(static_uuid)
        end
      end

      describe 'and the tester provides a notification body' do
        let(:notification_json_bundle) do
          File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_example_full_resource.json'))
        end

        it 'echoes the notification' do
          create_subscription_request
          inputs = { access_token:, notification_bundle: notification_json_bundle }
          result = run(test, inputs)
          expect(result.result).to eq('wait')

          notification_request = stub_request(:post, 'https://subscriptions.argo.run/fhir/r4/$subscription-hook')
            .to_return(status: 200)

          allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
          allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification) # skip notification
            .to receive(:rand).with(5..10).and_return(0)
          header('Authorization', "Bearer #{access_token}")
          post_json(submit_url, submit_request_json)

          expect(notification_request).to have_been_made.times(1)
          notifications = requests_repo.tagged_requests(result.test_session_id,
                                                        [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
          expect(notifications.length).to be(1)
          fhir_body = FHIR.from_contents(notifications[0].request_body)
          expect(fhir_body).to be_a(FHIR::Bundle)
          expect(fhir_body.entry.length).to be >= 1
          expect(fhir_body.entry[0].resource).to be_a(FHIR::Parameters)
          expect(fhir_body.entry[0].resource.id)
            .to eq(FHIR.from_contents(notification_json_bundle).entry[0].resource.id)
        end
      end
    end
  end
end
