require 'json'

# Guards the example Claim Update request Bundles shipped in the server presets: it loads each
# claim-update payload from the preset and confirms it satisfies the PAS Claim Update conformance
# checks (spec-65..72) implemented by the Client Suite verification tests. This keeps the example
# data (used by the loopback "Run Against the PAS Client Suite" preset) conformant over time.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::ClaimUpdateValidationUtils, :runnable do
  preset_path = File.expand_path(
    '../../../config/presets/pas_server_v221_run_against_pas_client.json.erb', __dir__
  )

  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:preset_inputs) do
    raw = File.read(preset_path)
    JSON.parse(raw.gsub(/<%=?.*?%>/m, 'PLACEHOLDER'))['inputs']
  end

  def payload(name)
    preset_inputs.find { |input| input['name'] == name }['value']
  end

  def seed(tag, value)
    repo_create(:request, direction: 'incoming', url: '/x', test_session_id: test_session.id, result:,
                          request_body: value, tags: [tag, DaVinciPASTestKit::SUBMIT_TAG], status: 200)
  end

  before do
    seed(DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG, payload('claim_update_initial_submit_payload'))
    seed(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, payload('claim_update_add_item_submit_payload'))
    seed(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG, payload('claim_update_modify_cancel_submit_payload'))
    seed(DaVinciPASTestKit::CLAIM_UPDATE_CANCEL_ALL_TAG, payload('claim_update_cancel_all_submit_payload'))
  end

  {
    'spec-65' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateReferencedClaimTest,
    'spec-66' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateGrandparentExcludedTest,
    'spec-67' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateReferencedResourcesTest,
    'spec-68' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateEntriesPreservedTest,
    'spec-69' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateCancelledEntriesTest,
    'spec-70' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateCancelledItemsCertificationTypeTest,
    'spec-71 and spec-72' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateChangedEntriesTest,
    'the cancel-entire-request check' => DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateCancelRequestTest
  }.each do |spec_id, test_class|
    it "example bundles satisfy #{spec_id}" do
      expect(run(test_class).result).to eq('pass')
    end
  end
end
