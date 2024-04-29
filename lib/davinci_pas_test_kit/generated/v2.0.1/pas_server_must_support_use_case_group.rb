require_relative 'pas_request_bundle/server_pas_request_bundle_validation_test'
require_relative 'claim/claim_operation_test'
require_relative 'pas_response_bundle/server_pas_response_bundle_validation_test'
require_relative 'pas_inquiry_request_bundle/server_pas_inquiry_request_bundle_validation_test'
require_relative 'claim_inquiry/claim_inquiry_operation_test'
require_relative 'pas_inquiry_response_bundle/server_pas_inquiry_response_bundle_validation_test'
require_relative 'pas_request_bundle/server_submit_request_pas_request_bundle_must_support_test'
require_relative 'claim_update/server_submit_request_claim_update_must_support_test'
require_relative 'coverage/server_submit_request_coverage_must_support_test'
require_relative 'encounter/server_submit_request_encounter_must_support_test'
require_relative 'insurer/server_submit_request_insurer_must_support_test'
require_relative 'requestor/server_submit_request_requestor_must_support_test'
require_relative 'beneficiary/server_submit_request_beneficiary_must_support_test'
require_relative 'subscriber/server_submit_request_subscriber_must_support_test'
require_relative 'practitioner/server_submit_request_practitioner_must_support_test'
require_relative 'practitioner_role/server_submit_request_practitioner_role_must_support_test'
require_relative 'pas_response_bundle/server_submit_response_pas_response_bundle_must_support_test'
require_relative 'claimresponse/server_submit_response_claimresponse_must_support_test'
require_relative 'communication_request/server_submit_response_communication_request_must_support_test'
require_relative 'insurer/server_submit_response_insurer_must_support_test'
require_relative 'requestor/server_submit_response_requestor_must_support_test'
require_relative 'beneficiary/server_submit_response_beneficiary_must_support_test'
require_relative 'practitioner/server_submit_response_practitioner_must_support_test'
require_relative 'practitioner_role/server_submit_response_practitioner_role_must_support_test'
require_relative 'task/server_submit_response_task_must_support_test'
require_relative 'pas_inquiry_request_bundle/server_inquiry_request_pas_inquiry_request_bundle_must_support_test'
require_relative 'claim_inquiry/server_inquiry_request_claim_inquiry_must_support_test'
require_relative 'coverage/server_inquiry_request_coverage_must_support_test'
require_relative 'insurer/server_inquiry_request_insurer_must_support_test'
require_relative 'requestor/server_inquiry_request_requestor_must_support_test'
require_relative 'beneficiary/server_inquiry_request_beneficiary_must_support_test'
require_relative 'subscriber/server_inquiry_request_subscriber_must_support_test'
require_relative 'practitioner/server_inquiry_request_practitioner_must_support_test'
require_relative 'practitioner_role/server_inquiry_request_practitioner_role_must_support_test'
require_relative 'pas_inquiry_response_bundle/server_inquiry_response_pas_inquiry_response_bundle_must_support_test'
require_relative 'claiminquiryresponse/server_inquiry_response_claiminquiryresponse_must_support_test'
require_relative 'insurer/server_inquiry_response_insurer_must_support_test'
require_relative 'requestor/server_inquiry_response_requestor_must_support_test'
require_relative 'beneficiary/server_inquiry_response_beneficiary_must_support_test'
require_relative 'practitioner/server_inquiry_response_practitioner_must_support_test'
require_relative 'practitioner_role/server_inquiry_response_practitioner_role_must_support_test'
require_relative 'task/server_inquiry_response_task_must_support_test'
require_relative '../../custom_groups/v2.0.1/must_support/pas_server_must_support_requirement_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASServerMustSupportUseCaseGroup < Inferno::TestGroup
      title 'Demonstrate Element Support'
      description %(
        Demonstrate the ability of the server to support all PAS-defined profiles
        and the must support elements defined in them. This includes
        
        - the ability to respond to prior authorization submission and inquiry
          requests that contain all PAS-defined profiles and their must support
          elements.
        - the ability to include in those responses all PAS-defined profiles
          and their must support elements.
        
        In order to allow Inferno to observe and validate these criteria, testers
        are required to provide a set of `$submit` and `$inquire` requests that
        collectively both themselves contain and elicit server responses that contain
        all PAS-defined profiles and their must support elements.
        
      )

      id :pas_server_v201_must_support_use_case
      
  
      def use_case
        'must_support'
      end
  
    
      group do
        title '$submit Element Support'
        description %(
          Check that the provided `$submit` requests both themselves contain
          and elicit server responses that contain all PAS-defined profiles
          and their must support elements.

          For `$submit` requests, this includes the following profiles:

          - [PAS Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-request-bundle.html)
          - [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-update.html)
          - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-coverage.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
          - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-encounter.html)
          - At least one of the following request profiles
            - [PAS Device Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-devicerequest.html)
            - [PAS Medication Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-medicationrequest.html)
            - [PAS Nutrition Order](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-nutritionorder.html)
            - [PAS Service Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-servicerequest.html)

          For `$submit` responses, this includes the following profiles (NOTE: request-specific
          profiles that may be echoed from `$submit` requests, such as the Claim instance or request instances,
          are not currently checked):
          
          - [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-response-bundle.html)
          - [PAS Claim Response](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claimresponse.html)
          - [PAS CommunicationRequest](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-communicationrequest.html)
          - [PAS Task](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
        )
        run_as_group
        
        group do
          title 'Submission of claims to the $submit operation for must support validation'
          
          test from: :pas_server_v201_pas_request_bundle_validation_test do
            id :pas_server_v201_pas_request_bundle_validation_test_must_support
            config(
              inputs: {
                pa_submit_request_payload: {
                  name: :must_support_pa_submit_request_payload,
                  title: 'Additional PAS Submit Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              }
            )
          end
          test from: :pas_v201_claim_operation_test do
            id :pas_v201_claim_operation_test_must_support
            config(
              inputs: {
                pa_submit_request_payload: {
                  name: :must_support_pa_submit_request_payload,
                  title: 'Additional PAS Submit Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              }
            )
          end
          test from: :pas_server_v201_pas_response_bundle_validation_test
        end
        group do
          title '[USER INPUT VALIDATION] Submit Request Must Support'
          
          test from: :pas_server_submit_v201_must_support_requirement
          test from: :pas_server_submit_request_v201_pas_request_bundle_must_support_test
          test from: :pas_server_submit_request_v201_claim_update_must_support_test
          test from: :pas_server_submit_request_v201_coverage_must_support_test
          test from: :pas_server_submit_request_v201_encounter_must_support_test
          test from: :pas_server_submit_request_v201_insurer_must_support_test
          test from: :pas_server_submit_request_v201_requestor_must_support_test
          test from: :pas_server_submit_request_v201_beneficiary_must_support_test
          test from: :pas_server_submit_request_v201_subscriber_must_support_test
          test from: :pas_server_submit_request_v201_practitioner_must_support_test
          test from: :pas_server_submit_request_v201_practitioner_role_must_support_test
        end
        group do
          title 'Submit Response Must Support'
          
          test from: :pas_server_submit_response_v201_pas_response_bundle_must_support_test
          test from: :pas_server_submit_response_v201_claimresponse_must_support_test
          test from: :pas_server_submit_response_v201_communication_request_must_support_test
          test from: :pas_server_submit_response_v201_insurer_must_support_test
          test from: :pas_server_submit_response_v201_requestor_must_support_test
          test from: :pas_server_submit_response_v201_beneficiary_must_support_test
          test from: :pas_server_submit_response_v201_practitioner_must_support_test
          test from: :pas_server_submit_response_v201_practitioner_role_must_support_test
          test from: :pas_server_submit_response_v201_task_must_support_test
        end
      end
      group do
        title '$inquire Element Support'
        description %(
          Check that the provided `$inquire` requests both themselves contain
          and elicit server responses that contain all PAS-defined profiles
          and their must support elements.

          For `$inquire` requests, this includes the following profiles:

          - [PAS Inquiry Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-request-bundle.html)
          - [PAS Claim Inquiry](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-inquiry.html)
          - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-coverage.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
          
          For `$inquire` responses, this includes the following profiles (NOTE: request-specific
          profiles that may be echoed from `$submit` requests, such as the Claim instance or request instances,
          are not currently checked):

          - [PAS Inquiry Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-request-bundle.html)
          - [PAS Claim Inquiry Response](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claiminquiryresponse.html)
          - [PAS Task](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
        )
        run_as_group
        
        group do
          title 'Submission of claims to the $inquire operation for must support validation'
          
          test from: :pas_server_v201_pas_inquiry_request_bundle_validation_test do
            id :pas_server_v201_pas_inquiry_request_bundle_validation_test_must_support
            config(
              inputs: {
                pa_inquire_request_payload: {
                  name: :must_support_pa_inquire_request_payload,
                  title: 'Additional PAS Inquire Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              }
            )
          end
          test from: :pas_v201_claim_inquiry_operation_test do
            id :pas_v201_claim_inquiry_operation_test_must_support
            config(
              inputs: {
                pa_inquire_request_payload: {
                  name: :must_support_pa_inquire_request_payload,
                  title: 'Additional PAS Inquire Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              }
            )
          end
          test from: :pas_server_v201_pas_inquiry_response_bundle_validation_test
        end
        group do
          title '[USER INPUT VALIDATION] Inquiry Request Must Support'
          
          test from: :pas_server_inquiry_request_v201_pas_inquiry_request_bundle_must_support_test
          test from: :pas_server_inquiry_request_v201_claim_inquiry_must_support_test
          test from: :pas_server_inquiry_request_v201_coverage_must_support_test
          test from: :pas_server_inquiry_request_v201_insurer_must_support_test
          test from: :pas_server_inquiry_request_v201_requestor_must_support_test
          test from: :pas_server_inquiry_request_v201_beneficiary_must_support_test
          test from: :pas_server_inquiry_request_v201_subscriber_must_support_test
          test from: :pas_server_inquiry_request_v201_practitioner_must_support_test
          test from: :pas_server_inquiry_request_v201_practitioner_role_must_support_test
        end
        group do
          title 'Inquiry Response Must Support'
          
          test from: :pas_server_inquiry_response_v201_pas_inquiry_response_bundle_must_support_test
          test from: :pas_server_inquiry_response_v201_claiminquiryresponse_must_support_test
          test from: :pas_server_inquiry_response_v201_insurer_must_support_test
          test from: :pas_server_inquiry_response_v201_requestor_must_support_test
          test from: :pas_server_inquiry_response_v201_beneficiary_must_support_test
          test from: :pas_server_inquiry_response_v201_practitioner_must_support_test
          test from: :pas_server_inquiry_response_v201_practitioner_role_must_support_test
          test from: :pas_server_inquiry_response_v201_task_must_support_test
        end
      end
  
    end
  end
end
