RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientResponseAttest, :request, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:random_id) { '1234' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:continue_pass_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{random_id}" }
  let(:continue_fail_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_FAIL_PATH}?token=#{random_id}" }
  let(:approval_attest_test) do
    described_class.config(options: { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                                      attest_message: 'blah blah' })
    described_class
  end

  describe 'When asking for an attestation' do
    it 'passes when responding true' do
      allow(SecureRandom).to receive(:hex).with(32).and_return(random_id)
      result = run(approval_attest_test)
      expect(result.result).to eq('wait')

      get continue_pass_url
      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'passes when responding false' do
      allow(SecureRandom).to receive(:hex).with(32).and_return(random_id)
      result = run(approval_attest_test)
      expect(result.result).to eq('wait')

      get continue_fail_url
      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end
  end
end
