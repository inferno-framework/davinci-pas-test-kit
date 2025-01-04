require_relative 'client_tests/pas_client_approval_submit_test'
require_relative 'client_tests/pas_client_approval_submit_response_attest'
require_relative '../../generated/v2.0.1/client_tests/client_pas_request_bundle_validation_test'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientApprovalGroup < Inferno::TestGroup
      id :pas_client_v201_approval_group
      title 'Demonstrate Approval Workflow'
      description %(
        Demonstrate the ability of the client to initiate a prior authorization
        request and respond appropriately to an 'approved' decision.
      )
      run_as_group

      test from: :pas_client_v201_approval_submit_test

      test from: :pas_client_v201_pas_request_bundle_validation_test,
           config: { options: { workflow_tag: APPROVAL_WORKFLOW_TAG } }

      test from: :pas_client_v201_approval_submit_response_attest
    end
  end
end
