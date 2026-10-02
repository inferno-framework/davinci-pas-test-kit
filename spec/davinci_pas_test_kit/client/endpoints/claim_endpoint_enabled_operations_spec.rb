require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/urls'
require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/workflows/pas_client_approval_submit_test'

# The approval submit test enables $submit and does not enable $inquire.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientApprovalSubmitTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:session_url_path) { '1234' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:submit_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:inquire_url) { "/custom/#{suite_id}/#{session_url_path}#{DaVinciPASTestKit::INQUIRE_PATH}" }
  let(:request_json) do
    JSON.parse(File.read(File.join(__dir__, '../../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
  end

  # The endpoint looks up the waiting test by id, so set the options on the test itself
  def with_options(overrides)
    allow(described_class.config).to receive(:options).and_wrap_original do |original|
      original.call.merge(overrides)
    end
    described_class
  end

  def expect_operation_not_supported(operation)
    expect(last_response.status).to eq(501)
    outcome = FHIR.from_contents(last_response.body)
    expect(outcome).to be_a(FHIR::OperationOutcome)
    expect(outcome.issue.first.code).to eq('not-supported')
    expect(outcome.issue.first.details.text).to include("$#{operation}")
  end

  describe 'for an operation the test does not enable' do
    it 'responds to an $inquire request with an OperationOutcome' do
      result = run(described_class, session_url_path:)
      expect(result.result).to eq('wait')

      post_json(inquire_url, request_json)

      expect_operation_not_supported('inquire')
    end

    it 'does not tag the request' do
      result = run(described_class, session_url_path:)
      post_json(inquire_url, request_json)

      expect(requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::INQUIRE_TAG])).to be_empty
      expect(requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG]))
        .to be_empty
    end

    it 'keeps waiting' do
      result = run(described_class, session_url_path:)
      post_json(inquire_url, request_json)

      expect(results_repo.find(result.id).result).to eq('wait')
    end

    it 'still handles requests for the enabled operation' do
      result = run(described_class, session_url_path:)
      post_json(inquire_url, request_json)
      post_json(submit_url, request_json)

      expect(last_response.status).to eq(200)
      expect(results_repo.find(result.id).result).to eq('pass')
      tagged = requests_repo.tagged_requests(result.test_session_id,
                                             [DaVinciPASTestKit::SUBMIT_TAG,
                                              DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG])
      expect(tagged.length).to eq(1)
    end
  end

  describe 'when $submit is explicitly disabled' do
    it 'responds to a $submit request with an OperationOutcome and keeps waiting' do
      result = run(with_options(submit_enabled: false), session_url_path:)
      post_json(submit_url, request_json)

      expect_operation_not_supported('submit')
      expect(requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::SUBMIT_TAG])).to be_empty
      expect(results_repo.find(result.id).result).to eq('wait')
    end
  end

  describe 'when the test does not specify the operation options' do
    it 'rejects $submit requests' do
      result = run(with_options(submit_enabled: nil), session_url_path:)
      post_json(submit_url, request_json)

      expect_operation_not_supported('submit')
      expect(results_repo.find(result.id).result).to eq('wait')
    end
  end

  describe 'when the test enables $inquire' do
    it 'tags and continues on an $inquire request' do
      result = run(with_options(inquire_enabled: true), session_url_path:)
      post_json(inquire_url, request_json)

      expect(results_repo.find(result.id).result).to eq('pass')
      expect(requests_repo.tagged_requests(result.test_session_id, [DaVinciPASTestKit::INQUIRE_TAG]).length).to eq(1)
    end
  end
end
