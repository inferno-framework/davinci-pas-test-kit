require_relative 'pas_request_bundle/server_pas_request_bundle_validation_test'
require_relative 'claim/claim_operation_test'
require_relative 'pas_response_bundle/server_pas_response_bundle_validation_test'
require_relative 'pas_inquiry_request_bundle/server_pas_inquiry_request_bundle_validation_test'
require_relative 'claim_inquiry/claim_inquiry_operation_test'
require_relative 'pas_inquiry_response_bundle/server_pas_inquiry_response_bundle_validation_test'
require_relative '../../custom_groups/v2.0.1/claim_status/pas_claim_status_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASServerPendedUseCaseGroup < Inferno::TestGroup
      title 'Successful Pended Workflow'
      description %(
        Demonstrate a complete prior authorization workflow including a period
        during which the final decision is pending. This includes
        
        - Demonstrating the ability of the server to respond to a prior
          authorization request with an `pended` status.
        - Demonstrating the ability of the server to respond to a subsequent
          inquiry request with a final decision for the request
        
      )

      id :pas_server_v201_pended_use_case
      run_as_group
  
      def use_case
        'pended'
      end
  
  
      group do
        title 'PAS Submit Operation'
        
        test from: :pas_server_v201_pas_request_bundle_validation_test do
          id :pas_server_v201_pas_request_bundle_validation_test_pended
          config(
            inputs: {
              pa_submit_request_payload: {
                name: :pended_pa_submit_request_payload ,
                title: 'PAS Submit Request Payload for Pended Response'
              }
            }
          )
        end
        test from: :pas_v201_claim_operation_test do
          id :pas_v201_claim_operation_test_pended
          config(
            inputs: {
              pa_submit_request_payload: {
                name: :pended_pa_submit_request_payload ,
                title: 'PAS Submit Request Payload for Pended Response'
              }
            }
          )
        end
        test from: :pas_server_v201_pas_response_bundle_validation_test
      end
      group do
        title 'PAS Status Check'
        
        test from: :prior_auth_claim_status
      end
      group do
        title 'PAS Inquiry Operation'
        
        test from: :pas_server_v201_pas_inquiry_request_bundle_validation_test
        test from: :pas_v201_claim_inquiry_operation_test do
          id :pas_v201_claim_inquiry_operation_test_pended
          config(
            inputs: {
              pa_submit_request_payload: {
                name: :pended_pa_submit_request_payload ,
                title: 'PAS Submit Request Payload for Pended Response'
              }
            }
          )
        end
        test from: :pas_server_v201_pas_inquiry_response_bundle_validation_test
      end
  
    end
  end
end
