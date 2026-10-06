require_relative '../../../../lib/davinci_pas_test_kit/client/v2.0.1/urls'

RSpec.describe DaVinciPASTestKit::AbstractResponseAttest, :request, :runnable do
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:continue_pass_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{wait_token}" }
  let(:continue_fail_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_FAIL_PATH}?token=#{wait_token}" }
  let(:base_options) do
    { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, attest_message: 'blah blah' }
  end
  let(:approval_attest_test) { attest_test_with(base_options) }

  # The test waits on a fresh random identifier, which it puts in the attestation URLs it outputs.
  def wait_token
    attest_true_url = Inferno::Repositories::SessionData.new.load(test_session_id: test_session.id,
                                                                  name: :attest_true_url)
    Rack::Utils.parse_query(URI(attest_true_url).query)['token']
  end

  def attest_test_with(options)
    Class.new(described_class) do
      include DaVinciPASTestKit::DaVinciPASV201::URLs

      def suite_id
        'davinci_pas_client_suite_v201'
      end

      config(options:)
    end
  end

  def create_tagged_request(tags:, status: 200, result: repo_create(:result, test_session_id: test_session.id))
    repo_create(
      :request,
      direction: 'incoming',
      url: "/custom/#{suite_id}/submit",
      test_session_id: test_session.id,
      result:,
      status:,
      tags:
    )
  end

  describe 'When asking for an attestation' do
    before { create_tagged_request(tags: [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG]) }

    it 'passes when responding true' do
      result = run(approval_attest_test)
      expect(result.result).to eq('wait')

      get continue_pass_url
      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'waits on a random identifier rather than the test session id' do
      result = run(approval_attest_test)

      expect(wait_token).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      get "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{test_session.id}"
      expect(results_repo.find(result.id).result).to eq('wait')
    end

    it 'passes when responding false' do
      result = run(approval_attest_test)
      expect(result.result).to eq('wait')

      get continue_fail_url
      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end
  end

  describe 'checking for requests before asking for an attestation' do
    let(:approval_tag) { DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG }

    def run_attest(extra_options = {})
      run(attest_test_with(base_options.merge(extra_options)))
    end

    describe 'when no requests were received' do
      it 'skips' do
        result = run_attest

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('No requests made demonstrating the Approval scenario')
      end

      it 'passes without waiting when no requests are ok' do
        result = run_attest(no_requests_ok: true)

        expect(result.result).to eq('pass')
        expect(result.result_message).to include('Attestation not needed')
      end

      it 'ignores requests tagged for other workflows' do
        create_tagged_request(tags: [DaVinciPASTestKit::DENIAL_WORKFLOW_TAG])

        expect(run_attest.result).to eq('skip')
      end
    end

    describe 'when one request was received' do
      it 'waits for the attestation when the response was successful and a success is expected' do
        create_tagged_request(tags: [approval_tag], status: 200)

        expect(run_attest.result).to eq('wait')
      end

      it 'skips when the response was an error but a success is expected' do
        create_tagged_request(tags: [approval_tag], status: 400)
        result = run_attest

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('expected to return a successful response')
      end

      it 'waits for the attestation when the response was an error and an error is expected' do
        create_tagged_request(tags: [approval_tag], status: 400)

        expect(run_attest(error_status_expected: true).result).to eq('wait')
      end

      it 'skips when the response was successful but an error is expected' do
        create_tagged_request(tags: [approval_tag], status: 200)
        result = run_attest(error_status_expected: true)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('expected to return a HTTP error response')
      end
    end

    describe 'when multiple requests were received' do
      before do
        shared_result = repo_create(:result, test_session_id: test_session.id)
        2.times { create_tagged_request(tags: [approval_tag], result: shared_result) }
      end

      it 'raises an implementation error' do
        result = run_attest

        expect(result.result).to eq('error')
        expect(result.result_message).to include('multiple requests tagged with workflow tag')
      end

      it 'waits for the attestation when multiple requests are ok' do
        expect(run_attest(multiple_requests_ok: true).result).to eq('wait')
      end
    end

    describe 'when multiple requests were received with mixed response statuses' do
      before do
        shared_result = repo_create(:result, test_session_id: test_session.id)
        create_tagged_request(tags: [approval_tag], status: 200, result: shared_result)
        create_tagged_request(tags: [approval_tag], status: 400, result: shared_result)
      end

      # e.g., one bad $submit among many good ones in the Must Support gather session
      it 'waits for the attestation when a success is expected and at least one response was successful' do
        expect(run_attest(multiple_requests_ok: true).result).to eq('wait')
      end

      it 'waits for the attestation when an error is expected and at least one response was an error' do
        expect(run_attest(multiple_requests_ok: true, error_status_expected: true).result).to eq('wait')
      end
    end

    describe 'when multiple requests were received with the same response status' do
      def create_requests(status)
        shared_result = repo_create(:result, test_session_id: test_session.id)
        2.times { create_tagged_request(tags: [approval_tag], status:, result: shared_result) }
      end

      it 'skips when a success is expected but every response was an error' do
        create_requests(400)
        result = run_attest(multiple_requests_ok: true)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('expected to return a successful response')
      end

      it 'skips when an error is expected but every response was successful' do
        create_requests(200)
        result = run_attest(multiple_requests_ok: true, error_status_expected: true)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('expected to return a HTTP error response')
      end
    end

    describe 'with an operation tag' do
      it 'only considers requests with both the workflow and operation tags' do
        create_tagged_request(tags: [approval_tag])

        result = run_attest(operation_tag: DaVinciPASTestKit::INQUIRE_TAG)

        expect(result.result).to eq('skip')
      end

      it 'waits when a request has both tags' do
        create_tagged_request(tags: [approval_tag, DaVinciPASTestKit::INQUIRE_TAG])

        expect(run_attest(operation_tag: DaVinciPASTestKit::INQUIRE_TAG).result).to eq('wait')
      end
    end

    describe 'with request tags' do
      let(:notification_tag) { DaVinciPASTestKit::REST_HOOK_EVENT_NOTIFICATION_TAG }

      def create_notification(status:)
        repo_create(:request, direction: 'outgoing', url: 'http://client.example.com/notify',
                              test_session_id: test_session.id,
                              result: repo_create(:result, test_session_id: test_session.id), status:,
                              tags: [notification_tag])
      end

      it 'skips when no request has the request tags, even if workflow requests exist' do
        create_tagged_request(tags: [approval_tag])

        expect(run_attest(request_tags: [notification_tag]).result).to eq('skip')
      end

      it 'waits when the client accepted the tagged request' do
        create_notification(status: 200)

        expect(run_attest(request_tags: [notification_tag]).result).to eq('wait')
      end

      it 'skips when the client returned an error for the tagged request' do
        create_notification(status: 500)
        result = run_attest(request_tags: [notification_tag])

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('client system did not return a successful response')
      end
    end

    it 'raises an implementation error for a workflow tag without a name' do
      create_tagged_request(tags: ['unknown_workflow'])
      result = run_attest(workflow_tag: 'unknown_workflow')

      expect(result.result).to eq('error')
      expect(result.result_message).to include('No name for workflow tag')
    end
  end

  describe 'pended workflow with both a $submit and an $inquire request' do
    let(:pended_tag) { DaVinciPASTestKit::PENDED_WORKFLOW_TAG }

    before do
      shared_result = repo_create(:result, test_session_id: test_session.id)
      create_tagged_request(tags: [pended_tag, DaVinciPASTestKit::SUBMIT_TAG], result: shared_result)
      create_tagged_request(tags: [pended_tag, DaVinciPASTestKit::INQUIRE_TAG], result: shared_result)
    end

    [DaVinciPASTestKit::SUBMIT_TAG, DaVinciPASTestKit::INQUIRE_TAG].each do |operation_tag|
      it "waits for the attestation for the #{operation_tag} interaction" do
        result = run(attest_test_with(workflow_tag: pended_tag, operation_tag:, multiple_requests_ok: true,
                                      attest_message: 'blah blah'))

        expect(result.result).to eq('wait')
      end
    end
  end
end
