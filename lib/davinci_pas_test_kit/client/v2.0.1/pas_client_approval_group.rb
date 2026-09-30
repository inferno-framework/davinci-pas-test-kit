require_relative 'workflows/pas_client_approval_submit_test'
require_relative 'workflows/pas_client_response_attest'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientApprovalGroup < Inferno::TestGroup
      id :pas_client_v201_approval_group
      title 'Approval Response'
      description %(
        During these tests, the client system will initiate a prior authorization
        request and show it can react appropriately to an 'approved' decision.
      )
      run_as_group

      input :approval_json_response, optional: true

      test from: :pas_client_v201_approval_submit_test
      test from: :pas_client_v201_request_bundle_validation_test,
           config: { options: { workflow_tag: APPROVAL_WORKFLOW_TAG } }

      test from: :pas_client_v201_response_bundle_validation_test,
           config: { options: { workflow_tag: APPROVAL_WORKFLOW_TAG } }
      test from: :pas_client_v201_response_attest,
           title: 'Check that the client registers the request as approved',
           description: %(
             During this test, the tester will observe the client system following
             the receipt of the approved response and attest that users are able to determine
             that the response has been approved.
           ),
           config: { options: {
             workflow_tag: APPROVAL_WORKFLOW_TAG,
             attest_message: 'I attest that the client system did not error when handling the `$submit` ' \
                             "response and displays the submitted claim as 'approved' meaning that the " \
                             'user can proceed with ordering or providing the requested service.'
           } }
    end
  end
end
