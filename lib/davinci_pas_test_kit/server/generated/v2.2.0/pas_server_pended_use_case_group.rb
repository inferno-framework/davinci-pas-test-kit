require_relative '../../server_request_bundle_validation_test'
require_relative '../../claim_submit_operation_test'
require_relative '../../server_response_bundle_validation_test'
require_relative '../../pas_claim_response_decision_test'
require_relative '../../v2.2.0/pas_server_subscription_notification_wait_test'
require 'subscriptions_test_kit/suites/subscriptions_r5_backport_r4_server/common/interaction_verification/notification_conformance_test'
require 'subscriptions_test_kit/suites/subscriptions_r5_backport_r4_server/event_notification/full_resource_content/full_resource_conformance_test'
require_relative '../../../pas_notification_conformance_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASServerPendedUseCaseGroup < Inferno::TestGroup
      id :pas_server_v220_pended_use_case
      title 'Successful Pended Workflow'
      description %(
        Demonstrate a complete prior authorization workflow including a period
        during which the final decision is pending. This includes demonstrating
        the ability of the server to
        
        - Respond to a prior authorization request with a `pended` status.
        - Accept a Subscription creation request and send a full-resource notification when
          the pended claim has been finalized.
        
      )
      run_as_group
  
      group do
        title "Server can respond with 'Pended' to claims submitted for prior authorization"
        
        test from: :pas_server_request_bundle_validation_test do
          id :pas_server_v220_pas_request_bundle_validation_test_pended
          title '[USER INPUT VALIDATION] Provided $submit Request Bundle is conformant'
          description %(
            **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
            Errors encountered will be treated as a skip instead of a failure.
            
            This test validates the conformity of the
            user input to the
            [PAS Request Bundle](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle|v2.2.0)
            profile, ensuring subsequent tests can accurately simulate content.
            
            It also checks that other conformance requirements defined in the [PAS Formal
            Specification](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html),
            such as the presence of all referenced instances within the bundle and the
            conformance of those instances to the appropriate profiles, are met.
            
            It verifies the presence of mandatory elements and that elements with
            required bindings contain appropriate values. CodeableConcept element
            bindings will fail if none of their codings have a code/system belonging
            to the bound ValueSet. Quantity, Coding, and code element bindings will
            fail if their code/system are not found in the valueset.
            
            Note that because X12 value sets are not public, elements bound to value
            sets containing X12 codes are not validated.
            
            **Limitations**
            
            Due to recognized errors in the PAS IG around extension context definitions,
            this test may not pass due to spurious errors of the form "The extension
            [extension url] is not allowed at this point". See [this
            issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues/11)
            for additional details.
            
          )
          config(
            inputs: {
              bundle_payload: {
                name: :pended_pa_submit_request_payload ,
                title: 'PAS Submit Request Payload for Pended Response'
              }
            },
            options: {
              operation: 'submit',
              use_case: 'pended',
              ig_version: 'v2.2.0'
            }
          )
        end
        test from: :pas_claim_submit_operation_test do
          id :pas_v220_claim_submit_operation_test_pended
          config(
            inputs: {
              pa_submit_request_payload: {
                name: :pended_pa_submit_request_payload,
                title: 'PAS Submit Request Payload for Pended Response'
              }
            },
            options: {
              use_case: 'pended',
              ig_version: 'v2.2.0'
            }
          )
        end
        test from: :pas_server_response_bundle_validation_test do
          id :pas_server_v220_pas_response_bundle_validation_test_pended
          title 'Server $submit Response Bundle is conformant'
          description %(
            This test validates the conformity of the
            server's response to the
            [PAS Response Bundle](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle|v2.2.0)
            profile.
            
            It also checks that other conformance requirements defined in the [PAS Formal
            Specification](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html),
            such as the presence of all referenced instances within the bundle and the
            conformance of those instances to the appropriate profiles, are met.
            
            It verifies the presence of mandatory elements and that elements with
            required bindings contain appropriate values. CodeableConcept element
            bindings will fail if none of their codings have a code/system belonging
            to the bound ValueSet. Quantity, Coding, and code element bindings will
            fail if their code/system are not found in the valueset.
            
            Note that because X12 value sets are not public, elements bound to value
            sets containing X12 codes are not validated.
            
            **Limitations**
            
            Due to recognized errors in the PAS IG around extension context definitions,
            this test may not pass due to spurious errors of the form "The extension
            [extension url] is not allowed at this point". See [this
            issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues/11)
            for additional details.
            
          )
          config(
            options: {
              use_case: 'pended',
              operation: 'submit',
              ig_version: 'v2.2.0'
            }
          )
        end
        test from: :prior_auth_claim_response_decision_validation do
          id :pas_server_v220_decision_validation_test_pended
          title "Server response includes the 'Pended' decision code in the ClaimResponse instance"
          config(
            options: {
              use_case: 'pended',
              operation: 'submit'
            }
          )
        end
      end
      group do
        title 'Server can notify client of updates via full-resource notification'
        
        test from: :pas_server_v220_subscription_notification_wait do
          id :pas_server_v220_subscription_notification_wait_pended
        end
        test from: :subscriptions_r4_server_notification_conformance do
          id :pas_server_v220_subscription_notification_conformance_pended
          config options: { subscription_type: 'full-resource' }
        end
        test from: :subscriptions_r4_server_full_resource_conformance do
          id :pas_server_v220_subscription_notification_full_resource_conformance_pended
        end
        test from: :pas_notification_pas_conformance_test
      end
    end
  end
end
