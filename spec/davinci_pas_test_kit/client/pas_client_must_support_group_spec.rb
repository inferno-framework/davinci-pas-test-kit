# The must support response inputs (ms_submit_responses/ms_inquire_responses) are declared
# on the gather-must-support wait test, but the Bundle Conformance groups' response
# validation tests need to read them too (to tell whether a tester-provided response was
# used - see PasClientResponseBundleValidationTest/PasClientInquireResponseBundleValidationTest
# #failed_entities_description). Inferno only propagates a group's inputs onto a test slot
# added with `test from:` after the input is declared on that group (see
# Inferno::DSL::Runnable#configure_child_class), so PASClientMustSupportGroup must declare
# these inputs itself, before its Bundle Conformance groups, for that to work - these specs
# guard against that declaration being dropped or moved after those groups again.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientMustSupportGroup do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }

  def response_validation_test(must_support_group, receive_group_title, test_id_suffix)
    must_support_group.groups
      .find { |group| group.title == receive_group_title }
      .tests
      .find { |test| test.id.to_s.end_with?(test_id_suffix) }
  end

  it 'propagates ms_submit_responses/ms_inquire_responses onto the bundle validation tests' do
    submit_response_test = response_validation_test(described_class, 'Demonstrate Must Support Coverage',
                                                    'pas_client_v221_response_bundle_validation_test')
    inquire_response_test = response_validation_test(described_class, 'Demonstrate Must Support Coverage',
                                                     'pas_client_v221_inquire_response_bundle_validation_test')

    expect(submit_response_test.inputs).to include(:ms_submit_responses)
    expect(inquire_response_test.inputs).to include(:ms_inquire_responses)
  end

  describe DaVinciPASTestKit::DaVinciPASV201::PASClientMustSupportGroup do
    let(:suite_id) { 'davinci_pas_client_suite_v201' }

    it 'propagates ms_submit_responses/ms_inquire_responses onto the bundle validation tests' do
      submit_response_test = response_validation_test(described_class, 'Demonstrate Must Support Coverage',
                                                      'pas_client_v201_response_bundle_validation_test')
      inquire_response_test = response_validation_test(described_class, 'Demonstrate Must Support Coverage',
                                                       'pas_client_v201_inquire_response_bundle_validation_test')

      expect(submit_response_test.inputs).to include(:ms_submit_responses)
      expect(inquire_response_test.inputs).to include(:ms_inquire_responses)
    end
  end
end
