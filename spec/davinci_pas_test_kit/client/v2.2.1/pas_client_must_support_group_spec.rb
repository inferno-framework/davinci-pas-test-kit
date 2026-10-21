RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientMustSupportGroup, :runnable do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:receive_group) { child_group('pas_client_v221_must_support_receive') }
  let(:coverage_group) { child_group('pas_client_v221_must_support_coverage') }
  let(:gather_test) { receive_group.tests.first }
  # The first coverage test, which fails with this message when it finds no $submit requests
  let(:submit_profiles_test) { coverage_group.groups.first.tests.first }
  let(:no_requests_message) { 'No submit requests received.' }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }

  # The instance in the suite, so that the groups and tests have the ids they are run under
  def group
    DaVinciPASTestKit::DaVinciPASV221::ClientSuite.groups
      .find { |child| child.id.to_s.end_with?('pas_client_v221_must_support_no_auth') }
  end

  def child_group(id_suffix)
    group.groups.find { |child| child.id.to_s.end_with?(id_suffix) }
  end

  def create_gather_request
    result = repo_create(:result, test_session_id: test_session.id, runnable: { test_id: gather_test.id })
    repo_create(:request, direction: 'incoming', url: submit_url, test_session_id: test_session.id, result:,
                          request_body: FHIR::Bundle.new(type: 'collection').to_json, response_body: '',
                          tags: [DaVinciPASTestKit::SUBMIT_TAG], status: 201)
  end

  describe 'structure' do
    it 'can be run one sub-group at a time' do
      expect(group.run_as_group?).to be(false)
      expect(group.groups).to eq([receive_group, coverage_group])
      expect(receive_group.run_as_group?).to be(true)
      expect(coverage_group.run_as_group?).to be(true)
    end

    it 'does not ask for the must support response inputs when only the coverage group is run' do
      input_names = coverage_group.available_inputs.keys
      expect(input_names).to_not include(:ms_submit_responses, :ms_inquire_responses)
      expect(receive_group.available_inputs.keys).to include(:ms_submit_responses, :ms_inquire_responses)
    end

    it 'keeps the must support analysis out of the group that waits for requests' do
      expect(receive_group.groups).to be_empty
      expect(coverage_group.groups.map { |child| child.id.to_s.split('-').last }).to eq(
        [
          'pas_client_v221_submit_must_support',
          'pas_client_v221_submit_response_must_support',
          'pas_client_v221_inquire_must_support',
          'pas_client_v221_inquire_response_must_support'
        ]
      )
    end
  end

  describe 'when the must support coverage group is re-run on its own' do
    it 'still evaluates the requests made during the demonstrate group' do
      create_gather_request

      run(coverage_group)
      result = run(submit_profiles_test)

      expect(result.result_message).to_not eq(no_requests_message)
    end

    it 'no longer evaluates them once the demonstrate group is re-run' do
      create_gather_request
      repo_create(:result, test_session_id: test_session.id, runnable: { test_id: gather_test.id })

      result = run(submit_profiles_test)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq(no_requests_message)
    end
  end
end
