require_relative 'pas_request_bundle/server_pas_request_bundle_validation_test'
require_relative 'claim/claim_operation_test'
require_relative 'pas_response_bundle/server_pas_response_bundle_validation_test'
require_relative 'pas_inquiry_request_bundle/server_pas_inquiry_request_bundle_validation_test'
require_relative 'claim_inquiry/claim_inquiry_operation_test'
require_relative 'pas_inquiry_response_bundle/server_pas_inquiry_response_bundle_validation_test'
require_relative '../../custom_groups/v2.0.1/claim_response_decision/pas_claim_response_decision_test'
require_relative '../../custom_groups/v2.0.1/notification/pas_subscription_notification_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASServerPendedUseCaseGroup < Inferno::TestGroup
      title 'Successful Pended Workflow'
      description %(
        Demonstrate a complete prior authorization workflow including a period
        during which the final decision is pending. This includes demonstrating
        the ability of the server to
        
        - Respond to a prior authorization request with a `pended` status.
        - Accept a Subscription creation request and send a notification when
          the pended claim has been finalized.
        - Respond to a subsequent inquiry request with a final decision for the request.
        
      )

      id :pas_server_v201_pended_use_case
      run_as_group
  
      def use_case
        'pended'
      end
  
      group do
        title 'Server can respond to claims submitted for prior authorization'
        
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
        test from: :prior_auth_claim_response_decision_validation
      end
      group do
        title 'Server can notify client of updates and respond to claims submitted for inquiry'
        
        test from: :prior_auth_claim_response_update_notification_validation
        test from: :subscriptions_r4_server_notification_conformance do
          config options: { subscription_type: 'id-only' }
          verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@145'
        end
        test from: :subscriptions_r4_server_id_only_conformance
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
