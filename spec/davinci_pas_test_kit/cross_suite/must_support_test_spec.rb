RSpec.describe DaVinciPASTestKit::MustSupportTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:inquire_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::INQUIRE_PATH}" }

  let(:json_pas_request_bundle) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  let(:json_pas_response_bundle) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
  end

  def create_submit_request(request_bundle_string, response_bundle_string, tags_list)
    create_request(submit_url, request_bundle_string, response_bundle_string, tags_list)
  end

  def create_inquire_request(request_bundle_string, response_bundle_string, tags_list)
    create_request(inquire_url, request_bundle_string, response_bundle_string, tags_list)
  end

  def create_request(url, request_bundle_string, response_bundle_string, tags_list)
    repo_create(
      :request,
      direction: 'incoming',
      url: url,
      test_session_id: test_session.id,
      result:,
      request_body: request_bundle_string,
      response_body: response_bundle_string,
      tags: tags_list,
      status: 201
    )
  end

  describe 'when PAS request bundle' do
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            resource_type: 'Bundle',
            profile_key: 'pas_request_bundle',
            user_input_validation: true,
            ig_version: 'v2.0.1',
            type: 'request',
            operation: 'submit'
          }
        )
      end
    end

    it 'passes if the request bundle contains all the must support elements' do
      create_submit_request(json_pas_request_bundle, '', [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'skips if the request bundle does not contain all the must support elements' do
      create_submit_request(FHIR::Bundle.new.to_json, '', [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/Could not find/)
    end
  end

  describe 'when PAS response bundle' do
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            resource_type: 'Bundle',
            profile_key: 'pas_response_bundle',
            user_input_validation: false,
            ig_version: 'v2.0.1',
            type: 'response',
            operation: 'submit'
          }
        )
      end
    end

    it 'passes if the response bundle contains all the must support elements' do
      create_submit_request('', json_pas_response_bundle, [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'fails if the response bundle does not contain all the must support elements' do
      create_submit_request('', FHIR::Bundle.new.to_json, [DaVinciPASTestKit::SUBMIT_TAG])

      result = run(test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Could not find/)
    end
  end

  describe 'when PAS inquiry request bundle' do
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            resource_type: 'Bundle',
            profile_key: 'pas_inquiry_request_bundle',
            user_input_validation: true,
            ig_version: 'v2.0.1',
            type: 'request',
            operation: 'inquire'
          }
        )
      end
    end

    it 'passes if the request bundle contains all the must support elements' do
      create_inquire_request(json_pas_request_bundle, '', [DaVinciPASTestKit::INQUIRE_TAG])

      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'skips if the request bundle does not contain all the must support elements' do
      create_inquire_request(FHIR::Bundle.new.to_json, '', [DaVinciPASTestKit::INQUIRE_TAG])

      result = run(test)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/Could not find/)
    end
  end

  describe 'when PAS inquiry response bundle' do
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            resource_type: 'Bundle',
            profile_key: 'pas_inquiry_response_bundle',
            user_input_validation: false,
            ig_version: 'v2.0.1',
            type: 'response',
            operation: 'inquire'
          }
        )
      end
    end

    it 'passes if the response bundle contains all the must support elements' do
      create_inquire_request('', json_pas_response_bundle, [DaVinciPASTestKit::INQUIRE_TAG])

      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'fails if the response bundle does not contain all the must support elements' do
      create_inquire_request('', FHIR::Bundle.new.to_json, [DaVinciPASTestKit::INQUIRE_TAG])

      result = run(test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Could not find/)
    end
  end

  describe 'When gathering data' do
    let(:test) do
      Class.new(described_class) do
        config(
          options: {
            resource_type: 'Patient',
            profile_key: 'subscriber',
            user_input_validation: true,
            ig_version: 'v2.0.1',
            type: 'request',
            operation: 'submit'
          }
        )
      end
    end

    it 'fails if no resources of a given type were returned in previous tests' do
      result = run(test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/No Patient resources were found/)
    end

    it 'pulls tagged requests from multiple workflows' do
      create_submit_request(json_pas_response_bundle, '', # gender, no birthDate
                            [DaVinciPASTestKit::SUBMIT_TAG, DaVinciPASTestKit::MUST_SUPPORT_WORKFLOW_TAG])
      create_submit_request( # birthDate, no gender
        json_pas_response_bundle.gsub('"gender" : "male"', '"birthDate" : "2026-01-29"'),
        '',
        [DaVinciPASTestKit::SUBMIT_TAG, DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG]
      )

      result = run(test)
      expect(result.result).to eq('skip')
      expect(result.result_message.include?('birthDate')).to be(false)
      expect(result.result_message.include?('gender')).to be(false)
    end
  end
end
