RSpec.describe DaVinciPASTestKit::MustSupportTest do
  let(:json_pas_request_bundle) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  let(:json_pas_response_bundle) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
  end

  let(:pas_request_bundle_must_support_test) do
    Inferno::Repositories::Tests.new.find('pas_server_submit_request_v201_pas_request_bundle_must_support_test')
  end

  let(:pas_response_bundle_must_support_test) do
    Inferno::Repositories::Tests.new.find('pas_server_submit_response_v201_pas_response_bundle_must_support_test')
  end

  let(:pas_inquiry_request_bundle_must_support_test) do
    Inferno::Repositories::Tests.new
      .find('pas_server_inquire_request_v201_pas_inquiry_request_bundle_must_support_test')
  end

  let(:pas_inquiry_response_bundle_must_support_test) do
    Inferno::Repositories::Tests.new
      .find('pas_server_inquire_response_v201_pas_inquiry_response_bundle_must_support_test')
  end

  let(:suite_id) { 'davinci_pas_server_suite_v201' }

  def execute_mock_test(runnable, bundle_resource, scratch_key)
    allow_any_instance_of(runnable)
      .to receive(:scratch).and_return(
        {
          "#{scratch_key}": {
            all: [bundle_resource]
          }
        }
      )
    run(runnable)
  end

  describe 'must support test' do
    # The scratch key in MS test should be the same as the scratch key in the validation test for a given profile.
    def run_expect_pass(runnable, bundle_resource, scratch_key)
      result = execute_mock_test(runnable, bundle_resource, scratch_key)
      expect(result.result).to eq('pass')
    end

    context 'when PAS request bundle' do
      scratch_key = 'submit_request_resources'
      it 'passes if the request bundle contains all the must support specified in the PAS Request Bundle profile' do
        run_expect_pass(pas_request_bundle_must_support_test, FHIR.from_contents(json_pas_request_bundle), scratch_key)
      end
    end

    context 'when PAS response bundle' do
      scratch_key = 'submit_response_resources'
      it 'passes if the response bundle contains all the must support specified in the PAS Response Bundle profile' do
        run_expect_pass(
          pas_response_bundle_must_support_test, FHIR.from_contents(json_pas_response_bundle), scratch_key
        )
      end
    end

    context 'when PAS inquiry request bundle' do
      scratch_key = 'inquire_request_resources'
      it 'passes if bundle contains all the must support specified in the PAS Inquiry Request Bundle profile' do
        run_expect_pass(
          pas_inquiry_request_bundle_must_support_test, FHIR.from_contents(json_pas_request_bundle), scratch_key
        )
      end
    end

    context 'when PAS inquiry response bundle' do
      scratch_key = 'inquire_response_resources'
      it 'passes if bundle contains all the must support specified in the PAS Inquiry Response Bundle profile' do
        run_expect_pass(
          pas_inquiry_response_bundle_must_support_test, FHIR.from_contents(json_pas_response_bundle), scratch_key
        )
      end
    end

    it 'fails if no resources of a given type were returned in previous tests' do
      result = run(pas_request_bundle_must_support_test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/No Bundle resources were found/)
    end
  end
end
