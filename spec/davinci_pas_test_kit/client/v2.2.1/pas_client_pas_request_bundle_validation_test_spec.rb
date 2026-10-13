RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasClientRequestBundleValidationTest do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:access_token) { '1234' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:us_core_patient_profile) { "#{DaVinciPASTestKit::PasBundleValidation::US_CORE_PROFILE_BASE}/us-core-patient" }
  let(:validated_profile_urls) { [] }
  # A Claim plus a Patient that nothing references, so the Patient gets no PAS profile from
  # reference traversal and falls back to US Core.
  let(:request_bundle_json) do
    FHIR::Bundle.new(
      type: 'collection',
      entry: [
        { fullUrl: 'urn:uuid:11111111-1111-4111-8111-111111111111',
          resource: FHIR::Claim.new(id: 'claim-1', status: 'active', use: 'preauthorization') },
        { fullUrl: 'urn:uuid:22222222-2222-4222-8222-222222222222',
          resource: FHIR::Patient.new(id: 'patient-1') }
      ]
    ).to_json
  end
  let(:test) do
    Class.new(described_class) do
      config({ options: { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG } })
    end
  end

  before do
    # Reference traversal hits the FHIRPath service and profile conformance the external
    # validator; neither is needed here, so record the profile each resource is validated
    # against instead.
    allow_any_instance_of(test).to receive(:evaluate_fhirpath).and_return([])
    allow_any_instance_of(test).to receive(:resource_is_valid?) do |_instance, **kwargs|
      validated_profile_urls << kwargs[:profile_url]
      true
    end
    create_submit_request(request_bundle_json, [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
  end

  def create_submit_request(bundle_string, tags_list)
    headers = [{ type: 'request', name: 'Authorization', value: "Bearer #{access_token}" }]
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body: bundle_string,
      tags: tags_list,
      status: 201,
      headers:
    )
  end

  def test_session_with_us_core_version(version)
    repo_create(:test_session, test_suite_id: suite_id,
                               suite_options: [Inferno::DSL::SuiteOption.new(id: :us_core_version, value: version)])
  end

  describe 'US Core Version suite option' do
    it 'lists US Core 3.1.1 first so it is the default selection' do
      option = suite.suite_options.find { |suite_option| suite_option.id == :us_core_version }

      expect(option.list_options.map { |list_option| list_option[:value] }).to eq(['3.1.1', '6.1.0', '7.0.0'])
    end

    it 'validates unprofiled resources against US Core 3.1.1 when the session keeps the default selection' do
      result = run(test)

      expect(result.result).to eq('pass')
      expect(validated_profile_urls).to include("#{us_core_patient_profile}|3.1.1")
    end

    ['3.1.1', '6.1.0', '7.0.0'].each do |version|
      context "when US Core #{version} is selected" do
        let(:test_session) { test_session_with_us_core_version(version) }

        it "validates unprofiled resources against US Core #{version}" do
          result = run(test)

          expect(result.result).to eq('pass')
          us_core_patient_urls = validated_profile_urls.grep(/us-core-patient/)
          expect(us_core_patient_urls).to eq(["#{us_core_patient_profile}|#{version}"])
        end
      end
    end
  end
end
