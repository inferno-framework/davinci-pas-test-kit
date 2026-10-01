require_relative '../../../../lib/davinci_pas_test_kit/client/v2.0.1/urls'

# Exercises the ClaimEndpoint response selection behavior for the must support workflow
RSpec.describe DaVinciPASTestKit::AbstractGatherMustSupportTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v201' }

  describe 'must support response selection' do
    let(:session_url_path) { '1234' }
    let(:test) do
      Class.new(described_class) do
        include DaVinciPASTestKit::DaVinciPASV201::URLs

        def suite_id
          'davinci_pas_client_suite_v201'
        end
      end
    end
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
    let(:inquire_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::INQUIRE_PATH}" }
    let(:submit_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
    end
    let(:inquire_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_inquire_bundle_v110.json')))
    end

    def response_bundle(id:, fixture: 'valid_pa_response_bundle.json')
      bundle = JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', fixture)))
      bundle['entry'][0]['resource']['id'] = id
      bundle
    end

    def wrapped_response_bundle(id:, criteria:, fixture: 'valid_pa_response_bundle.json')
      { 'criteria' => criteria, 'bundle' => response_bundle(id:, fixture:) }
    end

    def stub_fhirpath_service(expression, results)
      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => expression })
        .to_return(status: 200, body: results.to_json)
    end

    def returned_claim_response
      FHIR.from_contents(last_response.body).entry[0].resource
    end

    # Warnings recorded on the waiting test's result, which is where the tester sees them
    def result_warnings(result)
      Inferno::Repositories::Messages.new.messages_for_result(result.id)
        .select { |message| message.type == 'warning' }
        .map(&:message)
    end

    def result_infos(result)
      Inferno::Repositories::Messages.new.messages_for_result(result.id)
        .select { |message| message.type == 'info' }
        .map(&:message)
    end

    it 'returns a tester-provided response given as a single bare bundle' do
      inputs = { session_url_path:, ms_submit_responses: response_bundle(id: 'single-bundle').to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('single-bundle')
    end

    it 'returns a tester-provided response given as a single wrapper object' do
      inputs = { session_url_path:,
                 ms_submit_responses: wrapped_response_bundle(id: 'wrapped-bundle', criteria: nil).to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('wrapped-bundle')
    end

    it 'returns the bundle of the first entry when no entries specify criteria' do
      responses = [response_bundle(id: 'first'), response_bundle(id: 'second')]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('first')
    end

    it 'falls through to a bare bundle when earlier wrapper criteria do not match' do
      responses = [wrapped_response_bundle(id: 'for-later-requests', criteria: { 'requestRange' => '2-9' }),
                   response_bundle(id: 'fallback')]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('fallback')
    end

    # Request numbering relies on the URLs of previously persisted requests, which are built
    # from REQUEST_PATH. Puma sets it in production, but Rack::Test does not, so it must be
    # supplied explicitly for the persisted requests to be countable.
    def post_json_with_request_path(url, json)
      post(url, json.to_json, 'CONTENT_TYPE' => 'application/json', 'REQUEST_PATH' => url)
    end

    it 'selects bundles by request range across successive requests' do
      responses = [wrapped_response_bundle(id: 'for-request-1', criteria: { 'requestRange' => '1' }),
                   wrapped_response_bundle(id: 'for-later-requests', criteria: { 'requestRange' => '2-3' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json_with_request_path(submit_url, submit_request_json)
      expect(returned_claim_response.id).to eq('for-request-1')

      post_json_with_request_path(submit_url, submit_request_json)
      expect(returned_claim_response.id).to eq('for-later-requests')
    end

    it 'selects the first entry whose fhirpath criteria evaluate to true against the request' do
      responses = [wrapped_response_bundle(id: 'not-selected',
                                           criteria: { 'fhirpath' => 'Bundle.identifier.exists()' }),
                   wrapped_response_bundle(id: 'selected', criteria: { 'fhirpath' => 'Bundle.id.exists()' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.identifier.exists()', [{ type: 'boolean', element: false }])
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: true }])
      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('selected')
    end

    it 'returns only the inner bundle of a selected wrapper' do
      responses = [wrapped_response_bundle(id: 'with-criteria', criteria: { 'requestRange' => '1-9' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('with-criteria')
      returned = JSON.parse(last_response.body)
      expect(returned['resourceType']).to eq('Bundle')
      expect(returned).to_not have_key('criteria')
      expect(returned).to_not have_key('bundle')
    end

    it 'replaces {{fhirpath}} tokens with values evaluated against the request' do
      bundle = response_bundle(id: 'token-bundle')
      bundle['entry'][0]['resource']['preAuthRef'] = '{{Bundle.entry.first().resource.id}}'
      inputs = { session_url_path:, ms_submit_responses: bundle.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.entry.first().resource.id',
                            [{ type: 'string', element: 'ReferralAuthorizationExample' }])
      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.preAuthRef).to eq('ReferralAuthorizationExample')
    end

    it 'keeps the returned bundle parseable with consistent references after token replacement' do
      token = '{{Bundle.entry.first().resource.id}}'
      bundle = response_bundle(id: 'consistency-bundle')
      patient_entry = bundle['entry'].find { |e| e['resource']['resourceType'] == 'Patient' }
      patient_entry['fullUrl'] = "https://example.org/fhir/Patient/#{token}"
      patient_entry['resource']['id'] = token
      bundle['entry'][0]['resource']['patient']['reference'] = "Patient/#{token}"
      inputs = { session_url_path:, ms_submit_responses: { 'bundle' => bundle }.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.entry.first().resource.id',
                            [{ type: 'string', element: 'ReferralAuthorizationExample' }])
      post_json(submit_url, submit_request_json)

      returned = FHIR.from_contents(last_response.body)
      expect(returned).to be_a(FHIR::Bundle)
      full_urls = returned.entry.map(&:fullUrl)
      expect(full_urls.uniq.length).to eq(full_urls.length)
      returned_patient = returned.entry.find { |e| e.resource.resourceType == 'Patient' }
      expect(returned_patient.fullUrl).to eq('https://example.org/fhir/Patient/ReferralAuthorizationExample')
      expect(returned_patient.resource.id).to eq('ReferralAuthorizationExample')
      expect(returned.entry[0].resource.patient.reference).to eq('Patient/ReferralAuthorizationExample')
    end

    it 'skips an entry with an invalid request range and continues to later entries' do
      responses = [wrapped_response_bundle(id: 'bad-range', criteria: { 'requestRange' => '3-2' }),
                   response_bundle(id: 'fallback')]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('fallback')
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(/Invalid requestRange criteria "3-2"\. The corresponding Bundle was not selected/)
      )
    end

    it 'records a warning about the same invalid input only once across requests' do
      responses = [wrapped_response_bundle(id: 'bad-range', criteria: { 'requestRange' => '3-2' }),
                   response_bundle(id: 'fallback')]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)
      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.id).to eq('fallback')
      expect(result_warnings(result).length).to eq(1)
    end

    it 'generates a default response when the FHIRPath service returns an error during criteria evaluation' do
      responses = [wrapped_response_bundle(id: 'needs-fhirpath', criteria: { 'fhirpath' => 'Bundle.id.exists()' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => 'Bundle.id.exists()' })
        .to_return(status: 500, body: 'internal error')
      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(returned_claim_response.id).to_not eq('needs-fhirpath')
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(
          /Inferno will generate a default response.*HTTP 500 for query 'Bundle.id.exists\(\)': internal error/
        )
      )
    end

    it 'generates a default response when the FHIRPath service cannot be reached' do
      responses = [wrapped_response_bundle(id: 'needs-fhirpath', criteria: { 'fhirpath' => 'Bundle.id.exists()' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => 'Bundle.id.exists()' })
        .to_raise(Faraday::ConnectionFailed.new('connection refused'))
      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(/FHIRPath service request for query 'Bundle.id.exists\(\)' failed: connection refused/)
      )
    end

    it 'generates a default response when the FHIRPath service fails during token replacement' do
      bundle = response_bundle(id: 'token-bundle')
      bundle['entry'][0]['resource']['preAuthRef'] = '{{Bundle.id}}'
      inputs = { session_url_path:, ms_submit_responses: bundle.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => 'Bundle.id' })
        .to_return(status: 500, body: 'internal error')
      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(returned_claim_response.id).to_not eq('token-bundle')
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(/HTTP 500 for query 'Bundle.id': internal error/)
      )
    end

    it 'generates a default response with a warning when token replacement breaks the JSON structure' do
      bundle = response_bundle(id: 'token-bundle')
      bundle['entry'][0]['resource']['preAuthRef'] = '{{Bundle.id}}'
      inputs = { session_url_path:, ms_submit_responses: bundle.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      stub_fhirpath_service('Bundle.id', [{ type: 'string', element: 'value with "quotes"' }])
      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(returned_claim_response.id).to_not eq('token-bundle')
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(/not valid JSON after \{\{fhirpath\}\} token replacement/)
      )
    end

    it 'serves tester-provided bundles when the request URL includes a query string' do
      inputs = { session_url_path:, ms_submit_responses: response_bundle(id: 'query-string-bundle').to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json("#{submit_url}?foo=bar", submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('query-string-bundle')
    end

    it 'generates a default response when no provided entry matches' do
      responses = [wrapped_response_bundle(id: 'never-selected', criteria: { 'requestRange' => '5' })]
      inputs = { session_url_path:, ms_submit_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(returned_claim_response.id).to_not eq('never-selected')
    end

    it 'generates a default response with a warning when the input is not parseable' do
      inputs = { session_url_path:, ms_submit_responses: 'not json' }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(
          /default response: The 'Must Support \$submit Response Bundles' input is not valid JSON\./
        )
      )
    end

    it 'serves tester-provided bundles for inquire requests' do
      responses = [response_bundle(id: 'inquire-bundle', fixture: 'valid_pa_inquire_response_bundle.json')]
      inputs = { session_url_path:, ms_inquire_responses: responses.to_json }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(inquire_url, inquire_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('inquire-bundle')
    end

    describe 'notifications for pended must support responses' do
      let(:result) { repo_create(:result, test_session_id: test_session.id) }
      let(:requests_repo) { Inferno::Repositories::Requests.new }
      let(:subscription_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::FHIR_SUBSCRIPTION_PATH}" }
      let(:subscription_create_response_full_resource) do
        JSON.parse(
          File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_Subscription_example_full_resource.json'))
        )
      end
      let(:notification_endpoint) { 'https://subscriptions.argo.run/fhir/r4/$subscription-hook' }

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

      def notification_requests(test_session_id)
        requests_repo.tagged_requests(test_session_id, [DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG])
      end

      def notification_candidate(id:, notification:, criteria: nil, pended: false)
        bundle = pended ? pended_response_bundle(id:) : response_bundle(id:)
        candidate = { 'bundle' => bundle, 'notification' => notification }
        candidate['criteria'] = criteria if criteria
        candidate
      end

      # response_bundle's fixture ClaimResponse indicates approval (reviewActionCode A1); this
      # flips it to pended (A4) to exercise the pended-decision check on the notification trigger.
      def pended_response_bundle(id:)
        bundle = response_bundle(id:)
        claim_response = bundle['entry'][0]['resource']
        claim_response['item'].each do |item|
          item['adjudication'].each { |adjudication| set_review_action_code(adjudication, 'A4') }
        end
        bundle
      end

      def set_review_action_code(adjudication, code)
        review_action = adjudication['extension'].to_a.find do |ext|
          ext['url'] == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'
        end
        review_code = review_action&.dig('extension').to_a.find do |ext|
          ext['url'] == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'
        end
        return if review_code.blank?

        review_code['valueCodeableConcept']['coding'][0]['code'] = code
      end

      before do
        allow_any_instance_of(DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification)
          .to receive(:rand).with(5..10).and_return(0)
      end

      it 'sends a generated notification when the selected candidate asks Inferno to generate one' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 'generate')
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        notification_request = stub_request(:post, notification_endpoint).to_return(status: 200)
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_request).to have_been_made.times(1)
        expect(notification_requests(result.test_session_id).length).to eq(1)
      end

      it 'adds an info message when the notified response does not indicate a pended decision' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 'generate')
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        stub_request(:post, notification_endpoint).to_return(status: 200)
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(result_infos(result)).to contain_exactly(
          a_string_matching(/does not appear to indicate a pended decision/)
        )
      end

      it 'does not add that info message when the notified response indicates a pended decision' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 'generate', pended: true)
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        stub_request(:post, notification_endpoint).to_return(status: 200)
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(result_infos(result)).to be_empty
      end

      it 'sends the client_endpoint_access_token input as the bearer token on the notification request' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 'generate')
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json,
                   client_endpoint_access_token: 'ms-notification-token' }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        notification_request = stub_request(:post, notification_endpoint)
          .with(headers: { 'Authorization' => 'Bearer ms-notification-token' })
          .to_return(status: 200)
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_request).to have_been_made.times(1)
      end

      def notification_body_with_id(id)
        notification = JSON.parse(
          File.read(File.join(__dir__, '../../..', 'fixtures', 'PAS_notification_example_id_only.json'))
        )
        notification['entry'].first['resource']['id'] = id
        notification
      end

      it 'sends the entry selected by index from ms_notification_bodies when notification is a number' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 2)
        bodies = [notification_body_with_id('unselected-notification'),
                  notification_body_with_id('selected-notification')]
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json,
                   ms_notification_bodies: bodies.to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        notification_request = stub_request(:post, notification_endpoint).to_return(status: 200)
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_request).to have_been_made.times(1)
        notifications = notification_requests(result.test_session_id)
        expect(notifications.length).to eq(1)
        expect(FHIR.from_contents(notifications[0].request_body).entry[0].resource.id)
          .to eq('selected-notification')
      end

      it 'replaces {{fhirpath}} tokens in the selected ms_notification_bodies entry using the $submit request' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 1)
        body = notification_body_with_id('{{Bundle.entry.first().resource.id}}')
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json,
                   ms_notification_bodies: [body].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        notification_request = stub_request(:post, notification_endpoint).to_return(status: 200)
        stub_fhirpath_service('Bundle.entry.first().resource.id',
                              [{ type: 'string', element: 'ReferralAuthorizationExample' }])
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_request).to have_been_made.times(1)
        notifications = notification_requests(result.test_session_id)
        expect(FHIR.from_contents(notifications[0].request_body).entry[0].resource.id)
          .to eq('ReferralAuthorizationExample')
      end

      it 'generates a notification with a warning when token replacement breaks the JSON structure' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 1)
        body = notification_body_with_id('{{Bundle.id}}')
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json,
                   ms_notification_bodies: [body].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        notification_request = stub_request(:post, notification_endpoint).to_return(status: 200)
        stub_fhirpath_service('Bundle.id', [{ type: 'string', element: 'value with "quotes"' }])
        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_request).to have_been_made.times(1)
        expect(notification_requests(result.test_session_id).length).to eq(1)
        expect(result_warnings(result)).to contain_exactly(
          a_string_matching(/not valid JSON after \{\{fhirpath\}\} token replacement/)
        )
      end

      it 'does not send a notification when the selected candidate has no "notification" key' do
        create_subscription_request
        candidate = { 'bundle' => response_bundle(id: 'pended') }
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_requests(result.test_session_id)).to be_empty
      end

      it 'warns and sends nothing when the client has not created a Subscription yet' do
        candidate = notification_candidate(id: 'pended', notification: 'generate')
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_requests(result.test_session_id)).to be_empty
        expect(result_warnings(result)).to contain_exactly(
          a_string_matching(/has not created a Subscription yet/)
        )
      end

      it 'warns and sends nothing when the notification index is out of range' do
        create_subscription_request
        candidate = notification_candidate(id: 'pended', notification: 5)
        inputs = { session_url_path:, ms_submit_responses: [candidate].to_json,
                   ms_notification_bodies: [{ 'resourceType' => 'Bundle' }].to_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        post_json(submit_url, submit_request_json)

        expect(last_response.status).to be(200)
        expect(notification_requests(result.test_session_id)).to be_empty
        expect(result_warnings(result)).to contain_exactly(
          a_string_matching(/does not correspond to an entry in the 'Must Support Notification Bodies' input/)
        )
      end
    end
  end

  describe 'single tester-provided response (non must support workflow)' do
    let(:session_url_path) { '1234' }
    let(:test) do
      Class.new(DaVinciPASTestKit::AbstractApprovalSubmitTest) do
        include DaVinciPASTestKit::DaVinciPASV201::URLs

        def suite_id
          'davinci_pas_client_suite_v201'
        end
      end
    end
    let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
    let(:submit_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
    end
    let(:response_json) do
      JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle.json')))
    end

    def returned_claim_response
      FHIR.from_contents(last_response.body).entry[0].resource
    end

    def result_warnings(result)
      Inferno::Repositories::Messages.new.messages_for_result(result.id)
        .select { |message| message.type == 'warning' }
        .map(&:message)
    end

    it 'serves the provided response when it contains no tokens' do
      response_json['entry'][0]['resource']['id'] = 'approval-bundle'
      result = run(test, session_url_path:, approval_json_response: response_json.to_json)
      expect(result.result).to eq('wait')

      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response.id).to eq('approval-bundle')
    end

    it 'replaces {{fhirpath}} tokens in the provided response' do
      response_json['entry'][0]['resource']['preAuthRef'] = '{{Bundle.entry.first().resource.id}}'
      result = run(test, session_url_path:, approval_json_response: response_json.to_json)
      expect(result.result).to eq('wait')

      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => 'Bundle.entry.first().resource.id' })
        .to_return(status: 200, body: [{ type: 'string', element: 'ReferralAuthorizationExample' }].to_json)
      post_json(submit_url, submit_request_json)

      expect(returned_claim_response.preAuthRef).to eq('ReferralAuthorizationExample')
    end

    it 'generates a default response with a warning when the FHIRPath service fails during token replacement' do
      response_json['entry'][0]['resource']['id'] = 'approval-bundle'
      response_json['entry'][0]['resource']['preAuthRef'] = '{{Bundle.id}}'
      result = run(test, session_url_path:, approval_json_response: response_json.to_json)
      expect(result.result).to eq('wait')

      stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
        .with(query: { 'path' => 'Bundle.id' })
        .to_return(status: 500, body: 'internal error')
      post_json(submit_url, submit_request_json)

      expect(last_response.status).to be(200)
      expect(returned_claim_response).to be_a(FHIR::ClaimResponse)
      expect(returned_claim_response.id).to_not eq('approval-bundle')
      expect(result_warnings(result)).to contain_exactly(
        a_string_matching(/Unable to instantiate a tester-provided response.*HTTP 500 for query 'Bundle.id'/)
      )
    end
  end
end
