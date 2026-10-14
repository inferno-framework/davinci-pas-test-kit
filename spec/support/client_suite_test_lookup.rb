# Finds a test as included in the v2.2.1 client suite, where the suite-level validators are defined. Uses
# the no-auth groups, which keep the :session_url_path input that identifies the test session for
# requests from the client.
module ClientSuiteTestLookup
  # @param top_group_id [Symbol] the suite's no-auth group, e.g. :pas_client_v221_workflows_no_auth.
  # @param group_id [Symbol] the id of the group within it that includes the test.
  # @param test_id [Symbol] the id of the test, as defined.
  def v221_client_suite_test(top_group_id, group_id, test_id)
    top_group = DaVinciPASTestKit::DaVinciPASV221::ClientSuite.groups
      .find { |group| group.id.to_s.end_with?(top_group_id.to_s) }
    find_descendant_test(top_group, group_id.to_s, test_id.to_s)
  end

  def v221_client_workflow_test(group_id, test_id)
    v221_client_suite_test(:pas_client_v221_workflows_no_auth, group_id, test_id)
  end

  private

  def find_descendant_test(group, group_id, test_id)
    if group.id.to_s.end_with?(group_id)
      test = group.tests.find { |child| child.id.to_s.end_with?(test_id) }
      return test if test.present?
    end
    group.groups.each do |child|
      test = find_descendant_test(child, group_id, test_id)
      return test if test.present?
    end
    nil
  end
end
