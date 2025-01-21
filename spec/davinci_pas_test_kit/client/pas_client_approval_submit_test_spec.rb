RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientApprovalSubmitTest, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }

  describe 'responding to requests from the client under tests' do
    let(:access_token) { '1234' }
    let(:static_uuid) { 'f015a331-3a86-4566-b72f-b5b85902cdca' }
    let(:test) { described_class }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:requests_repo) { Inferno::Repositories::Requests.new }
    let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
    let(:submit_request_json) do
      JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
    end

    it 'passes when a submit request received' do
      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(submit_url, submit_request_json)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'tags submit requests' do
      inputs = { access_token: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{access_token}")
      post_json(submit_url, submit_request_json)

      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                        DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(requests.length).to be(1)
    end

    describe 'when the tester does not provide a response body' do
      it 'generates an approved response body' do
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
          expect(review_action_code.valueCodeableConcept&.coding&.dig(0)&.code).to eq('A1')
        end
      end
    end

    describe 'when the tester provides a response body' do
      let(:approved_response_json) do
        File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
      end

      it 'echoes the response body' do
        inputs = { access_token:, approval_json_response: approved_response_json }
        result = run(test, inputs)
        expect(result.result).to eq('wait')

        allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
        header('Authorization', "Bearer #{access_token}")
        post_json(submit_url, submit_request_json)
        fhir_body = FHIR.from_contents(last_response.body)
        expect(fhir_body).to be_a(FHIR::Bundle)
        expect(fhir_body.entry.length).to be >= 1
        expect(fhir_body.entry[0].resource).to be_a(FHIR::ClaimResponse)
        expect(fhir_body.entry[0].resource.id).to eq(FHIR.from_contents(approved_response_json).entry[0].resource.id)
      end
    end
  end
end
