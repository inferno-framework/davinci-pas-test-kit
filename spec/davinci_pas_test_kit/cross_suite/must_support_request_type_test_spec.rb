RSpec.describe DaVinciPASTestKit::MustSupportRequestTypeTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }

  let(:test) do
    Class.new(described_class) do
      config(
        options: {
          profile_keys: ['device_request', 'medication_request', 'nutrition_order', 'service_request'],
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end

  let(:all_requests_missing_must_supports_bundle_json) do
    bundle = FHIR::Bundle.new
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::DeviceRequest.new })
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::MedicationRequest.new })
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::NutritionOrder.new })
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::ServiceRequest.new })
    bundle.to_json
  end

  let(:device_request_missing_must_supports_bundle_json) do
    bundle = FHIR::Bundle.new
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::DeviceRequest.new })
    bundle.to_json
  end

  let(:json_pas_device_request_all_must_supports) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'pas_device_request_all_must_support.json'))
  end

  let(:device_request_all_must_supports_bundle_json) do
    bundle = FHIR::Bundle.new
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR.from_contents(json_pas_device_request_all_must_supports) })
    bundle.to_json
  end

  let(:all_requests_but_device_request_missing_must_supports_bundle_json) do
    bundle = FHIR::Bundle.new
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR.from_contents(json_pas_device_request_all_must_supports) })
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::MedicationRequest.new })
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::NutritionOrder.new })
    bundle.entry << FHIR::Bundle::Entry.new({ resource: FHIR::ServiceRequest.new })
    bundle.to_json
  end

  def create_submit_request(request_bundle_string, response_bundle_string, tags_list)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body: request_bundle_string,
      response_body: response_bundle_string,
      tags: tags_list,
      status: 201
    )
  end

  describe 'when only the DeviceRequest type present' do
    it 'passes if the request bundle contains DeviceRequests with all the must support elements' do
      create_submit_request(device_request_all_must_supports_bundle_json, '', [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'fails if the request bundle does not contain DeviceRequests with all the must support elements' do
      create_submit_request(device_request_missing_must_supports_bundle_json, '', [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Could not find/)
    end
  end

  describe 'when all request types present' do
    it 'indicates problems for all request types when each missing must supports' do
      create_submit_request(all_requests_missing_must_supports_bundle_json, '', [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Could not find/)
      expect(result.result_message).to match(/provided DeviceRequest/)
      expect(result.result_message).to match(/provided MedicationRequest/)
      expect(result.result_message).to match(/provided NutritionOrder/)
      expect(result.result_message).to match(/provided ServiceRequest/)
    end

    it 'does not indicate problems for request types with no missing must supports' do
      create_submit_request(all_requests_but_device_request_missing_must_supports_bundle_json, '',
                            [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Could not find/)
      expect(result.result_message).to_not match(/provided DeviceRequest/)
      expect(result.result_message).to match(/provided MedicationRequest/)
      expect(result.result_message).to match(/provided NutritionOrder/)
      expect(result.result_message).to match(/provided ServiceRequest/)
    end
  end
end
