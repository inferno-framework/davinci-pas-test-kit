require_relative 'client_tests/pas_client_approval_submit_test'
require_relative 'client_tests/pas_client_response_attest'
require_relative 'client_tests/pas_client_request_bundle_validation_test'
require_relative 'client_tests/pas_client_response_bundle_validation_test'
require_relative 'client_tests/pas_client_review_submit_attest'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientApprovalGroup < Inferno::TestGroup
      id :pas_client_v201_approval_group
      title 'Approval Workflow'
      description %(
        During these tests, the client will initiate a prior authorization
        request and show it can respond appropriately to an 'approved' decision.
      )
      run_as_group

      input :approval_json_response, optional: true

      test from: :pas_client_v201_approval_submit_test
      test from: :pas_client_v201_request_bundle_validation_test,
           config: { options: { workflow_tag: APPROVAL_WORKFLOW_TAG } }

      test from: :pas_client_v201_response_bundle_validation_test,
           config: { options: { workflow_tag: APPROVAL_WORKFLOW_TAG } }
      test from: :pas_client_v201_response_attest,
           title: 'Check that the client registers the request as approved (Attestation)',
           description: %(
             This test provides the tester an opportunity to observe their client following
             the receipt of the approved response and attest that users are able to determine
             that the response has been approved.
           ),
           config: { options: {
             workflow_tag: APPROVAL_WORKFLOW_TAG,
             attest_message: "I attest that the client system displays the submitted claim as 'approved' meaning " \
                             'that the user can proceed with ordering or providing the requested service.'
           } }
      test from: :pas_client_v201_review_submit_attest,
           config: { options: {
             workflow_tag: APPROVAL_WORKFLOW_TAG
           } }
    end
  end
end
