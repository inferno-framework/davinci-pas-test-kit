require_relative '../../../../lib/davinci_pas_test_kit/client/v2.2.1/error_handling/' \
                 'pas_client_operation_outcome_validation_test'
require_relative '../../../support/client_suite_test_lookup'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientOperationOutcomeValidationTest, :request do
  include ClientSuiteTestLookup

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  # The validators are defined on the suite, so run the copy of the test within it.
  let(:test) { v221_client_workflow_test(:pas_client_v221_operation_failure_group, described_class.id) }
  let(:submit_url) { "/custom/#{suite_id}/1234#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:custom_extension_url) { 'urn:inferno-custom' }
  let(:conformant_operation_outcome) do
    FHIR::OperationOutcome.new(
      issue: [{ severity: 'error', code: 'invalid',
                details: { text: 'The submitted Bundle could not be processed.' } }]
    )
  end
  let(:custom_extension_operation_outcome) do
    FHIR::OperationOutcome.new(
      extension: [{ url: custom_extension_url, valueString: 'x' }],
      issue: conformant_operation_outcome.issue
    )
  end
  let(:validator_success) do
    { outcomes: [{ issues: [] }], sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2' }
  end
  # The message the HL7 validator reports for an extension it can't resolve when
  # custom extensions are not allowed.
  let(:unknown_extension_message) do
    "OperationOutcome.extension[0]: The extension #{custom_extension_url} could not be found " \
      'so is not allowed here'
  end
  let(:validator_unknown_extension) do
    {
      outcomes: [{
        issues: [{ level: 'ERROR', location: 'OperationOutcome.extension[0]', message: unknown_extension_message }]
      }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
    }
  end

  def validation_context_from(request)
    body = JSON.parse(request.body)
    body['validationContext'] || body['cliContext']
  end

  def create_operation_failure_request(response_body)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags: [DaVinciPASTestKit::OPERATION_FAILURE_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
      status: 400
    )
  end

  # The suite's copy of the test requires the tester-provided OperationOutcome input, although
  # the test itself validates the response body that was actually returned.
  def run_test(operation_outcome = conformant_operation_outcome)
    run(test, operation_failure_operation_outcome: operation_outcome.to_json)
  end

  def error_messages_for(result)
    Inferno::Repositories::Messages.new.messages_for_result(result.id).select { |m| m.type == 'error' }
  end

  it 'skips when no Operation Failure $submit requests were received' do
    result = run_test

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No responses to verify')
  end

  it 'passes for a conformant OperationOutcome' do
    stub_request(:post, validation_url).to_return(status: 200, body: validator_success.to_json)
    create_operation_failure_request(conformant_operation_outcome.to_json)

    result = run_test

    expect(result.result).to eq('pass')
  end

  it 'validates without allowing custom extensions' do
    stub_request(:post, validation_url).to_return(status: 200, body: validator_success.to_json)
    create_operation_failure_request(conformant_operation_outcome.to_json)

    run_test

    expect(a_request(:post, validation_url).with { |req| validation_context_from(req)['extensions'] == [] })
      .to have_been_made.once
  end

  describe 'with an OperationOutcome containing a custom extension' do
    before do
      stub_request(:post, validation_url).to_return(status: 200, body: validator_unknown_extension.to_json)
      create_operation_failure_request(custom_extension_operation_outcome.to_json)
    end

    it 'skips with a message noting that custom extensions are not allowed' do
      result = run_test(custom_extension_operation_outcome)

      expect(result.result).to eq('skip')
      expect(result.result_message).to include('contains custom extensions')
      expect(result.result_message).to include('See Messages for details')
    end

    it 'reports the unknown extension error in Messages' do
      result = run_test(custom_extension_operation_outcome)

      expect(error_messages_for(result).map(&:message))
        .to include(a_string_including("#{custom_extension_url} could not be found"))
    end
  end
end
