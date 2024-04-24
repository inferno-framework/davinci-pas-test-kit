require_relative 'pas_request_bundle/server_pas_request_bundle_validation_test'
require_relative 'claim/claim_operation_test'
require_relative 'pas_response_bundle/server_pas_response_bundle_validation_test'
require_relative '../../custom_groups/v2.0.1/claim_response_decision/pas_claim_response_decision_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASServerApprovalUseCaseGroup < Inferno::TestGroup
      title 'Successful Approval Workflow'
      description %(
        Demonstrate the ability of the server to respond to a prior
        authorization request with an `approved` decision.
        
      )

      id :pas_server_v201_approval_use_case
      run_as_group
  
      def use_case
        'approval'
      end
  
  
      group do
        title 'PAS Submit Operation'
        
        test from: :pas_server_v201_pas_request_bundle_validation_test do
          id :pas_server_v201_pas_request_bundle_validation_test_approval
          config(
            inputs: {
              pa_submit_request_payload: {
                name: :approval_pa_submit_request_payload ,
                title: 'PAS Submit Request Payload for Approval Response'
              }
            }
          )
        end
        test from: :pas_v201_claim_operation_test do
          id :pas_v201_claim_operation_test_approval
          config(
            inputs: {
              pa_submit_request_payload: {
                name: :approval_pa_submit_request_payload ,
                title: 'PAS Submit Request Payload for Approval Response'
              }
            }
          )
        end
        test from: :pas_server_v201_pas_response_bundle_validation_test
      end
      group do
        title 'PAS Claim Response Decision Validation'
        
        test from: :prior_auth_claim_response_decision_validation
      end
  
    end
  end
end
