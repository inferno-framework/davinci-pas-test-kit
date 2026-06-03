RSpec.describe DaVinciPASTestKit::ClaimSubmitOperationTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:requests_repo) { Inferno::Repositories::Requests.new }

  let(:test) do
    Class.new(described_class) do
      fhir_client { url :server_endpoint }
      input :server_endpoint
      config(
        options: {
          use_case: 'approval'
        }
      )
    end
  end

  let(:pa_submit_request_payload) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  describe 'when dealing with invalid inputs' do
    it 'skips if no bundles to submit provided' do
      result = run(test, server_endpoint:)
      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/No bundle request provided/)
    end

    it 'fails if provided bundle is invalid json' do
      result = run(test, pa_submit_request_payload: 'not json', server_endpoint:)
      expect(result.result).to eq('fail')
      expect(result.result_message)
        .to match(/Invalid JSON. Provide valid json to use for the \$submit during the Approval workflow./)
    end
  end

  describe 'when submitting one request' do
    it 'passes if the PA response has a 200 status for Claim/$submit operation' do
      stub_request(:post, "#{server_endpoint}/Claim/$submit")
        .with(
          body: JSON.parse(pa_submit_request_payload)
        )
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      result = run(test, pa_submit_request_payload:, server_endpoint:)
      expect(result.result).to eq('pass')
      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                        DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(requests.size).to eq(1)
    end

    it 'fails if the PA response has a status other than 200 or 201 for Claim/$submit operation' do
      stub_request(:post, "#{server_endpoint}/Claim/$submit")
        .with(
          body: JSON.parse(pa_submit_request_payload)
        )
        .to_return(status: 400, body: FHIR::Bundle.new.to_json)

      result = run(test, pa_submit_request_payload:, server_endpoint:)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Unexpected response status/)
      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                        DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(requests.size).to eq(1)
    end

    it 'fails if the PA response is not a bundle' do
      stub_request(:post, "#{server_endpoint}/Claim/$submit")
        .with(
          body: JSON.parse(pa_submit_request_payload)
        )
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      result = run(test, pa_submit_request_payload:, server_endpoint:)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Unexpected resource type/)
      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                        DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(requests.size).to eq(1)
    end

    it 'fails if the PA response is not json' do
      stub_request(:post, "#{server_endpoint}/Claim/$submit")
        .with(
          body: JSON.parse(pa_submit_request_payload)
        )
        .to_return(status: 200, body: 'not json')

      result = run(test, pa_submit_request_payload:, server_endpoint:)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Invalid JSON. Server response to \$submit was not json./)
      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                        DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(requests.size).to eq(1)
    end

    # NOTE: tried to check warning on a long-running response, but Time.now was called
    # as a part of rspec as well, so wasn't able to figure out how to control the mock well enough
  end

  describe 'when submitting multiple requests' do
    it 'makes all requests even if some fail' do
      stub = stub_request(:post, "#{server_endpoint}/Claim/$submit")
        .to_return(status: 400, body: FHIR::Bundle.new.to_json)

      result =
        run(test,
            pa_submit_request_payload: "[#{pa_submit_request_payload},#{pa_submit_request_payload}]",
            server_endpoint:)
      expect(result.result).to eq('fail')
      expect(stub).to have_been_made.twice
      requests = requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG,
                                                                        DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(requests.size).to eq(2)
    end
  end
end
