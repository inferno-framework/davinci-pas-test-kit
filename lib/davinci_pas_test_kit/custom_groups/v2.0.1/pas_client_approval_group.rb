require_relative 'client_tests/pas_client_approval_submit_test'
require_relative 'client_tests/pas_client_approval_submit_response_attest'
require_relative 'client_tests/pas_client_pas_request_bundle_validation_test'
require_relative 'client_tests/pas_client_denial_pas_response_bundle_validation_test'
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

      input :approval_json_response,
            title: 'Claim approved response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be sent in response to $submit requests during this test
              to indicate that the request has been approved.
              It will be updated to make creation timestamps current.
              If not provided, an approval response will be generated from the submitted Claim.
              In either case, the response will be validated against the PAS Response Bundle profile.
            )

      test from: :pas_client_v201_approval_submit_test
      test from: :pas_client_v201_pas_request_bundle_validation_test,
           config: { options: { workflow_tag: APPROVAL_WORKFLOW_TAG } }
      test from: :pas_client_v201_approval_pas_response_bundle_validation_test
      test from: :pas_client_v201_approval_submit_response_attest
    end
  end
end
