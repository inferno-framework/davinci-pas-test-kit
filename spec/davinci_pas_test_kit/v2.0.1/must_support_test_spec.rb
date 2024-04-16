RSpec.describe DaVinciPASTestKit::MustSupportTest do
  let(:json_string_stub) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  let(:pas_request_bundle_must_support_test) do
    Inferno::Repositories::Tests.new.find('pas_server_submit_request_v201_pas_request_bundle_must_support_test')
  end

  let(:suite) { Inferno::Repositories::TestSuites.new.find('davinci_pas_server_suite_v201') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }

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

  # def generate_request_bundle_resource(json_addition)
  #   complete_json_string = json_string_stub + json_addition
  #   return FHIR.from_contents(complete_json_string)
  # end

  def execute_mock_test(request_bundle_resource)
    allow_any_instance_of(pas_request_bundle_must_support_test)
      .to receive(:scratch_resources).and_return(
        {
          all: [request_bundle_resource]
        }
      )
    run(pas_request_bundle_must_support_test)
  end

  describe 'must support test for PAS request bundle' do
    def run_expect_pass(request_bundle_resource)
      result = execute_mock_test(request_bundle_resource)
      expect(result.result).to eq('pass')
    end

    it 'passes if the request bundle contains all the must support specified in the PAS Request Bundle profile' do
      run_expect_pass(FHIR.from_contents(json_string_stub))
    end
  end
end
