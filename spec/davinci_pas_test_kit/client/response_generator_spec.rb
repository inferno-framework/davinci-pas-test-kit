RSpec.describe DaVinciPASTestKit::ResponseGenerator do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite) { Inferno::Repositories::TestSuites.new.find('davinci_pas_client_suite_v201') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:validator_url) { ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL') }
  let(:operation_outcome_success) do
    {
      outcomes: [{
        issues: []
      }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
    }
  end
  let(:module_instance) { Class.new { include DaVinciPASTestKit::ResponseGenerator }.new }
  let(:submit_request_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end
  let(:submit_request_multiple_items_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110_multiple_items.json'))
  end
  let(:submit_request_claim_uuid_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110_uuid.json'))
  end
  let(:submit_response_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
  end
  let(:submit_response_missing_elements) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'pa_response_bundle_missing_elements.json'))
  end
  let(:id_only_notification_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_example_id_only.json'))
  end
  let(:full_resource_notification_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_example_full_resource.json'))
  end
  let(:missing_elements_notification_string) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_missing_elements.json'))
  end
  let(:notification_verification_test) do
    Class.new(Inferno::Test) do
      include DaVinciPASTestKit::ResponseGenerator
      include SubscriptionsTestKit::NotificationConformanceVerification
      fhir_resource_validator do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')

        cli_context do
          txServer nil
          displayWarnings true
          disableDefaultResourceFetcher true
        end

        igs('hl7.fhir.uv.subscriptions-backport#1.1.0')
      end

      input :submit_response_string, :notification_type, :subscription_url, :subscription_topic
      input :status,
            optional: true
      input :decision,
            optional: true

      run do
        notification_bundle_string = if notification_type == 'full-resource'
                                       mock_full_resource_notification_bundle(
                                         submit_response_string,
                                         subscription_url,
                                         subscription_topic,
                                         decision
                                       )
                                     else
                                       mock_id_only_notification_bundle(
                                         submit_response_string,
                                         subscription_url,
                                         subscription_topic
                                       )

                                     end
        notification_verification(notification_bundle_string, 'event-notification',
                                  subscription_id: subscription_url.split('/').last, status:)
        if notification_type == 'full-resource'
          full_resource_event_notification_verification(notification_bundle_string, 'ClaimResponse')
        else
          id_only_event_notification_verification(notification_bundle_string, 'ClaimResponse')
        end
        no_error_verification('There were verification errors')
      end
    end
  end

  before do
    Inferno::Repositories::Tests.new.insert(notification_verification_test)
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  describe 'When mocking responses' do
    it 'returns nil if no Claim in the request' do
      returned_response_string = module_instance.mock_response_bundle(
        FHIR::Bundle.new,
        'submit',
        :approval,
        nil
      )
      expect(returned_response_string).to be_nil
    end

    describe 'and populating meta.profile on ClaimResponse' do
      it 'indicates claimresponse for $submit responses' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_string),
          'submit',
          :approval,
          nil
        )

        claim_response_profile = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claimresponse'
        returned_bundle = FHIR.from_contents(returned_response_string)
        expect(returned_bundle).to be_a(FHIR::Bundle)
        claim_response = returned_bundle.entry.find { |entry| entry.resource.is_a?(FHIR::ClaimResponse) }.resource
        expect(claim_response).to_not be_nil
        expect(claim_response.meta&.profile&.find { |profile| profile == claim_response_profile }).to_not be_nil
      end

      it 'indicates claiminquiryresponse for $inquire responses' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_string),
          'inquire',
          :approval,
          nil
        )

        claim_response_profile = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claiminquiryresponse'
        returned_bundle = FHIR.from_contents(returned_response_string)
        expect(returned_bundle).to be_a(FHIR::Bundle)
        claim_response = returned_bundle.entry.find { |entry| entry.resource.is_a?(FHIR::ClaimResponse) }.resource
        expect(claim_response).to_not be_nil
        expect(claim_response.meta&.profile&.find { |profile| profile == claim_response_profile }).to_not be_nil
      end
    end

    describe 'and populating timestamps' do
      it 'uses the current time' do
        time_now = Time.now
        allow(Time).to receive(:now).and_return(time_now)
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_string),
          'inquire',
          :approval,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        expect(response_bundle.timestamp).to eq(time_now.iso8601)
        claim_response = response_bundle.entry.find { |entry| entry.resource.is_a?(FHIR::ClaimResponse) }.resource
        expect(claim_response).to_not be_nil
        expect(claim_response.created).to eq(time_now.iso8601)
      end
    end

    describe 'and populating item.adjudiction' do
      it 'includes an ClaimResponse.item for each item in the submitted claim' do
        request_bundle = FHIR.from_contents(submit_request_multiple_items_string)
        request_item_count = request_bundle.entry.find do |entry|
                               entry.resource.is_a?(FHIR::Claim)
                             end&.resource&.item&.length

        returned_response_string = module_instance.mock_response_bundle(
          request_bundle,
          'inquire',
          :approval,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        response_item_count = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end&.resource&.item&.length
        expect(response_item_count).to be(request_item_count)
      end

      it 'can use an approved decision' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'inquire',
          :approval,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        claim_response = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end&.resource
        expect(claim_response).to_not be_nil
        claim_response.item&.each do |item|
          expect(item.adjudication).to_not be_nil
          expect(item.adjudication.length).to be >= 1
          approved_review_action_code = nil
          item.adjudication.each do |adjudication|
            review_action_ext = adjudication.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction' }
            review_action_code_ext = review_action_ext&.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode' }
            approved_review_action_code = review_action_code_ext&.valueCodeableConcept&.coding&.find do |coding|
              coding.code == 'A1'
            end
            break if approved_review_action_code.present?
          end
          expect(approved_review_action_code).to_not be_nil
        end
      end

      it 'can use a denied decision' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'inquire',
          :denial,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        claim_response = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end&.resource
        expect(claim_response).to_not be_nil
        claim_response.item&.each do |item|
          expect(item.adjudication).to_not be_nil
          expect(item.adjudication.length).to be >= 1
          denied_review_action_code = nil
          item.adjudication.each do |adjudication|
            review_action_ext = adjudication.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction' }
            review_action_code_ext = review_action_ext&.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode' }
            denied_review_action_code = review_action_code_ext&.valueCodeableConcept&.coding&.find do |coding|
              coding.code == 'A3'
            end
            break if denied_review_action_code.present?
          end
          expect(denied_review_action_code).to_not be_nil
        end
      end

      it 'can use a pended decision' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'submit',
          :pended,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        claim_response = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end&.resource
        expect(claim_response).to_not be_nil
        claim_response.item&.each do |item|
          expect(item.adjudication).to_not be_nil
          expect(item.adjudication.length).to be >= 1
          pended_review_action_code = nil
          item.adjudication.each do |adjudication|
            review_action_ext = adjudication.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction' }
            review_action_code_ext = review_action_ext&.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode' }
            pended_review_action_code = review_action_code_ext&.valueCodeableConcept&.coding&.find do |coding|
              coding.code == 'A4'
            end
            break if pended_review_action_code.present?
          end
          expect(pended_review_action_code).to_not be_nil
        end
      end

      it 'defaults to an approved decision' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'submit',
          nil,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        claim_response = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end&.resource
        expect(claim_response).to_not be_nil
        claim_response.item&.each do |item|
          expect(item.adjudication).to_not be_nil
          expect(item.adjudication.length).to be >= 1
          approved_review_action_code = nil
          item.adjudication.each do |adjudication|
            review_action_ext = adjudication.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction' }
            review_action_code_ext = review_action_ext&.extension&.find { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode' }
            approved_review_action_code = review_action_code_ext&.valueCodeableConcept&.coding&.find do |coding|
              coding.code == 'A1'
            end
            break if approved_review_action_code.present?
          end
          expect(approved_review_action_code).to_not be_nil
        end
      end
    end

    describe 'and populating the ClaimResponse id' do
      it 'uses the provided value' do
        provided_uuid = SecureRandom.uuid
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'submit',
          :approval,
          provided_uuid
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        claim_response_entry = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end
        expect(claim_response_entry).to_not be_nil
        expect(claim_response_entry.fullUrl).to eq("urn:uuid:#{provided_uuid}")
        expect(claim_response_entry.resource.id).to eq(provided_uuid)
      end

      it 'generates a uuid when no value provided' do
        fixed_uuid = SecureRandom.uuid
        allow(SecureRandom).to receive(:uuid).and_return(fixed_uuid)

        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'submit',
          :approval,
          nil
        )

        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        claim_response_entry = response_bundle.entry.find do |entry|
          entry.resource.is_a?(FHIR::ClaimResponse)
        end
        expect(claim_response_entry).to_not be_nil
        expect(claim_response_entry.fullUrl).to eq("urn:uuid:#{fixed_uuid}")
        expect(claim_response_entry.resource.id).to eq(fixed_uuid)
      end
    end

    describe 'and including referenced entries' do
      it 'all entries included when using absolute url references' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_multiple_items_string),
          'submit',
          :approval,
          nil
        )

        base_url = 'https://prior-auth.davinci.hl7.org/fhir/'
        expected_entries = ['Organization/UMOExample', 'Organization/InsurerExample', 'Patient/SubscriberExample']
        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        expect(response_bundle.entry.length).to be(4)
        expected_entries.each do |expected_ref|
          expected_type = expected_ref.split('/').first
          expected_id = expected_ref.split('/').last
          found_entry = response_bundle.entry.find do |entry|
            entry.resource.id == expected_id && entry.resource.resourceType == expected_type
          end
          expect(found_entry).to_not be_nil
          expect(found_entry.fullUrl).to eq("#{base_url}#{expected_ref}")
        end
      end

      it 'all entries included when using uuid references' do
        returned_response_string = module_instance.mock_response_bundle(
          FHIR.from_contents(submit_request_claim_uuid_string),
          'submit',
          :approval,
          nil
        )

        base_url = 'urn:uuid:'
        expected_entries = ['75832284-6c15-488c-8237-0290624d5b91', '75832284-6c15-488c-8237-0290624d5b92',
                            '75832284-6c15-488c-8237-0290624d5b94']
        response_bundle = FHIR.from_contents(returned_response_string)
        expect(response_bundle).to_not be_nil
        expect(response_bundle.entry.length).to be(4)
        expected_entries.each do |expected_uuid|
          found_entry = response_bundle.entry.find do |entry|
            entry.resource.id == expected_uuid
          end
          expect(found_entry).to_not be_nil
          expect(found_entry.fullUrl).to eq("#{base_url}#{expected_uuid}")
        end
      end
    end
  end

  describe 'When modifying responses' do
    it 'updates timestamps to the current time' do
      time_now = Time.now
      allow(Time).to receive(:now).and_return(time_now)
      returned_response_string = module_instance.update_tester_provided_response(
        submit_response_string,
        nil
      )

      bundle = FHIR.from_contents(returned_response_string)
      expect(bundle.timestamp).to eq(time_now.iso8601)
      claim_response = bundle.entry.find { |entry| entry.resource.is_a?(FHIR::ClaimResponse) }.resource
      expect(claim_response).to_not be_nil
      expect(claim_response.created).to eq(time_now.iso8601)
    end

    it 'updates Claim references if a new reference provided' do
      old_claim_reference = "urn:uuid:#{SecureRandom.uuid}"
      bundle_with_claim = FHIR.from_contents(submit_response_string)
      claim_response_with_claim = bundle_with_claim.entry.find do |entry|
        entry.resource.is_a?(FHIR::ClaimResponse)
      end.resource
      claim_response_with_claim.request = FHIR::Reference.new(
        reference: old_claim_reference
      )

      updated_claim_reference = "urn:uuid:#{SecureRandom.uuid}"
      returned_response_string = module_instance.update_tester_provided_response(
        bundle_with_claim.to_json,
        updated_claim_reference
      )

      bundle = FHIR.from_contents(returned_response_string)
      claim_response = bundle.entry.find { |entry| entry.resource.is_a?(FHIR::ClaimResponse) }.resource
      expect(claim_response).to_not be_nil
      expect(claim_response.request.reference).to eq(updated_claim_reference)
    end

    it 'leaves Claim references alone if no updated reference provided' do
      returned_response_string = module_instance.update_tester_provided_response(
        submit_response_string,
        nil
      )

      bundle = FHIR.from_contents(returned_response_string)
      claim_response = bundle.entry.find { |entry| entry.resource.is_a?(FHIR::ClaimResponse) }.resource
      expect(claim_response).to_not be_nil
      expect(claim_response.request).to be_nil
    end

    it 'makes no changes when relevant elements not present' do
      updated_claim_reference = "urn:uuid:#{SecureRandom.uuid}"
      returned_response_string = module_instance.update_tester_provided_response(
        submit_response_missing_elements,
        updated_claim_reference
      )

      expect(returned_response_string).to eq(submit_response_missing_elements)
    end

    it 'makes no changes when non-FHIR json' do
      non_fhir_json_string = '{ "not" : "fhir" }'
      updated_claim_reference = "urn:uuid:#{SecureRandom.uuid}"
      returned_response_string = module_instance.update_tester_provided_response(
        non_fhir_json_string,
        updated_claim_reference
      )

      expect(returned_response_string).to eq(non_fhir_json_string)
    end
  end

  describe 'When mocking notifications' do
    describe 'for id-only Subscriptions' do
      it 'returns a structurally-correct notification' do
        stub_request(:post, "#{validator_url}/validate") # profile validation not performed
          .to_return(status: 200, body: operation_outcome_success.to_json)
        inputs = {
          submit_response_string:,
          notification_type: 'id-only',
          subscription_url: 'https://inferno.healthit.gov/suites/custom/davinci_pas_client_suite_v201/fhir/Subscription/sample',
          subscription_topic: 'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'
        }
        result = run(notification_verification_test, inputs)

        expect(result.result).to eq('pass')
      end
    end

    describe 'for full-resource Subscriptions' do
      it 'returns a structurally-correct notification' do
        stub_request(:post, "#{validator_url}/validate") # profile validation not performed
          .to_return(status: 200, body: operation_outcome_success.to_json)
        inputs = {
          submit_response_string:,
          notification_type: 'full-resource',
          subscription_url: 'https://inferno.healthit.gov/suites/custom/davinci_pas_client_suite_v201/fhir/Subscription/sample',
          subscription_topic: 'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic',
          decision: :approval
        }
        result = run(notification_verification_test, inputs)

        expect(result.result).to eq('pass')
      end
    end

    describe 'and populating the focus' do
      it 'uses the ClaimResponse fullUrl from the submit response' do
        returned_notification_string = module_instance.mock_id_only_notification_bundle(
          submit_response_string,
          'https://inferno.healthit.gov/suites/custom/davinci_pas_client_suite_v201/fhir/Subscription/sample',
          'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'
        )

        target_focus_reference = FHIR.from_contents(submit_response_string).entry[0].fullUrl
        bundle = FHIR.from_contents(returned_notification_string)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        focus_subparam = event_param&.part&.find { |param| param.name == 'focus' }
        expect(focus_subparam).to_not be_nil
        expect(focus_subparam.valueReference.reference).to eq(target_focus_reference)
      end

      it 'uses a random value if the response is not fhir' do
        allow(SecureRandom).to receive(:uuid).and_return('dummy_uuid')
        returned_notification_string = module_instance.mock_id_only_notification_bundle(
          '{ "not" : "fhir" }',
          'https://inferno.healthit.gov/suites/custom/davinci_pas_client_suite_v201/fhir/Subscription/sample',
          'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'
        )

        target_focus_reference = 'urn:uuid:dummy_uuid'
        bundle = FHIR.from_contents(returned_notification_string)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        focus_subparam = event_param&.part&.find { |param| param.name == 'focus' }
        expect(focus_subparam).to_not be_nil
        expect(focus_subparam.valueReference.reference).to eq(target_focus_reference)
      end
    end

    describe 'and populating timestamps' do
      it 'uses the current time' do
        time_now = Time.now
        allow(Time).to receive(:now).and_return(time_now)
        returned_notification_string = module_instance.mock_id_only_notification_bundle(
          submit_response_string,
          'https://inferno.healthit.gov/suites/custom/davinci_pas_client_suite_v201/fhir/Subscription/sample',
          'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'
        )

        bundle = FHIR.from_contents(returned_notification_string)
        expect(bundle.timestamp).to eq(time_now.utc.iso8601)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        timestamp_subparam = event_param&.part&.find { |param| param.name == 'timestamp' }
        expect(timestamp_subparam).to_not be_nil
        expect(timestamp_subparam.valueInstant).to eq(time_now.utc.iso8601)
      end
    end

    describe 'When updating provided notifications' do
      it 'updates to the current time' do
        time_now = Time.now
        allow(Time).to receive(:now).and_return(time_now)
        returned_notification_string = module_instance.update_tester_provided_notification(
          id_only_notification_string,
          nil
        )

        bundle = FHIR.from_contents(returned_notification_string)
        expect(bundle.timestamp).to eq(time_now.utc.iso8601)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        timestamp_subparam = event_param&.part&.find { |param| param.name == 'timestamp' }
        expect(timestamp_subparam).to_not be_nil
        expect(timestamp_subparam.valueInstant).to eq(time_now.utc.iso8601)
      end

      it 'leaves the notification focus the same if no update provided' do
        returned_notification_string = module_instance.update_tester_provided_notification(
          id_only_notification_string,
          nil
        )

        target_focus_reference = FHIR.from_contents(id_only_notification_string).entry[0].resource.parameter
          .find { |param| param.name == 'notification-event' }
          .part.find { |param| param.name == 'focus' }
          .valueReference.reference

        bundle = FHIR.from_contents(returned_notification_string)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        focus_subparam = event_param&.part&.find { |param| param.name == 'focus' }
        expect(focus_subparam).to_not be_nil
        expect(focus_subparam.valueReference.reference).to eq(target_focus_reference)
      end

      it 'updates the notification focus if a uuid provided' do
        target_focus_reference = 'dummy-uuid'
        returned_notification_string = module_instance.update_tester_provided_notification(
          id_only_notification_string,
          target_focus_reference
        )

        bundle = FHIR.from_contents(returned_notification_string)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        focus_subparam = event_param&.part&.find { |param| param.name == 'focus' }
        expect(focus_subparam).to_not be_nil
        expect(focus_subparam.valueReference.reference).to eq("urn:uuid:#{target_focus_reference}")
      end

      it 'updates the focused entry if a uuid provided' do
        target_focus_reference = 'dummy-uuid'
        returned_notification_string = module_instance.update_tester_provided_notification(
          full_resource_notification_string,
          target_focus_reference
        )

        bundle = FHIR.from_contents(returned_notification_string)
        event_param = bundle.entry[0].resource.parameter.find { |param| param.name == 'notification-event' }
        focus_subparam = event_param&.part&.find { |param| param.name == 'focus' }
        expect(focus_subparam).to_not be_nil
        expect(focus_subparam.valueReference.reference).to eq("urn:uuid:#{target_focus_reference}")

        focus_entry = bundle.entry.find { |entry| entry.fullUrl == "urn:uuid:#{target_focus_reference}" }
        expect(focus_entry).to_not be_nil
        expect(focus_entry.resource.id).to eq(target_focus_reference)
      end

      it 'makes no updates when relevant elements are not present in the provided content' do
        target_focus_reference = 'dummy-uuid'
        returned_notification_string = module_instance.update_tester_provided_notification(
          missing_elements_notification_string,
          target_focus_reference
        )
        expect(returned_notification_string).to eq(missing_elements_notification_string)
      end
    end
  end
end
