require_relative '../../server_request_bundle_validation_test'
require_relative '../../claim_submit_operation_test'
require_relative '../../server_response_bundle_validation_test'
require_relative '../../claim_inquire_operation_test'
require_relative '../../v2.0.1/must_support/pas_server_must_support_request_profiles_test'
require_relative 'pas_request_bundle/server_submit_request_must_support_pas_request_bundle_test'
require_relative 'claim_update/server_submit_request_must_support_claim_update_test'
require_relative 'coverage/server_submit_request_must_support_coverage_test'
require_relative 'encounter/server_submit_request_must_support_encounter_test'
require_relative 'insurer/server_submit_request_must_support_insurer_test'
require_relative 'requestor/server_submit_request_must_support_requestor_test'
require_relative 'beneficiary/server_submit_request_must_support_beneficiary_test'
require_relative 'subscriber/server_submit_request_must_support_subscriber_test'
require_relative 'practitioner/server_submit_request_must_support_practitioner_test'
require_relative 'practitioner_role/server_submit_request_must_support_practitioner_role_test'
require_relative 'pas_response_bundle/server_submit_response_must_support_pas_response_bundle_test'
require_relative 'claimresponse/server_submit_response_must_support_claimresponse_test'
require_relative 'communication_request/server_submit_response_must_support_communication_request_test'
require_relative 'insurer/server_submit_response_must_support_insurer_test'
require_relative 'requestor/server_submit_response_must_support_requestor_test'
require_relative 'beneficiary/server_submit_response_must_support_beneficiary_test'
require_relative 'practitioner/server_submit_response_must_support_practitioner_test'
require_relative 'practitioner_role/server_submit_response_must_support_practitioner_role_test'
require_relative 'task/server_submit_response_must_support_task_test'
require_relative 'pas_inquiry_request_bundle/server_inquire_request_must_support_pas_inquiry_request_bundle_test'
require_relative 'claim_inquiry/server_inquire_request_must_support_claim_inquiry_test'
require_relative 'coverage/server_inquire_request_must_support_coverage_test'
require_relative 'insurer/server_inquire_request_must_support_insurer_test'
require_relative 'requestor/server_inquire_request_must_support_requestor_test'
require_relative 'beneficiary/server_inquire_request_must_support_beneficiary_test'
require_relative 'subscriber/server_inquire_request_must_support_subscriber_test'
require_relative 'practitioner/server_inquire_request_must_support_practitioner_test'
require_relative 'practitioner_role/server_inquire_request_must_support_practitioner_role_test'
require_relative 'pas_inquiry_response_bundle/server_inquire_response_must_support_pas_inquiry_response_bundle_test'
require_relative 'claiminquiryresponse/server_inquire_response_must_support_claiminquiryresponse_test'
require_relative 'insurer/server_inquire_response_must_support_insurer_test'
require_relative 'requestor/server_inquire_response_must_support_requestor_test'
require_relative 'beneficiary/server_inquire_response_must_support_beneficiary_test'
require_relative 'practitioner/server_inquire_response_must_support_practitioner_test'
require_relative 'practitioner_role/server_inquire_response_must_support_practitioner_role_test'
require_relative 'task/server_inquire_response_must_support_task_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASServerMustSupportGroup < Inferno::TestGroup
      id :pas_server_v201_must_support
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

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@33'


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
          - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-encounter.html)
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
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
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
          - [PAS Task](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html)
          
          
          
        )
        run_as_group

        group do
          title 'Submission of claims to the $submit operation for must support validation'

          test from: :pas_server_request_bundle_validation_test do
            id :pas_server_v201_submit_request_bundle_validation_test_must_support
            title '[USER INPUT VALIDATION] Provided $submit Request Bundle is conformant'
            description %(
              **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
            Errors encountered will be treated as a skip instead of a failure.
            
            This test validates the conformity of the
            user input to the
            [PAS Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-request-bundle.html)
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
                  name: :must_support_pa_submit_request_payload ,
                  title: 'Additional $submit Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              },
              options: {
                operation: 'submit',
                use_case: 'must_support',
                ig_version: 'v2.0.1'
              }
            )
          end
          test from: :pas_claim_submit_operation_test do
            id :pas_v201_claim_submit_operation_test_must_support
            config(
              inputs: {
                pa_submit_request_payload: {
                  name: :must_support_pa_submit_request_payload,
                  title: 'Additional $submit Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              },
              options: {
                use_case: 'must_support',
                ig_version: 'v2.0.1'
              }
            )
          end
          test from: :pas_server_response_bundle_validation_test do
            id :pas_server_v201_submit_response_bundle_validation_test_must_support
            title 'Server $submit Response Bundle is conformant'
            description %(
              This test validates the conformity of the
              server's response to the
              [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-response-bundle.html)
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
                use_case: 'must_support',
                operation: 'submit',
                ig_version: 'v2.0.1'
              }
            )
          end
        end

        group do
          title '[USER INPUT VALIDATION] $submit Request Must Support'
          verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@35'

          test from: :pas_server_v201_must_support_request_profiles
          test from: :pas_server_v201_submit_request_must_support_pas_request_bundle
          test from: :pas_server_v201_submit_request_must_support_claim_update
          test from: :pas_server_v201_submit_request_must_support_coverage
          test from: :pas_server_v201_submit_request_must_support_encounter
          test from: :pas_server_v201_submit_request_must_support_insurer
          test from: :pas_server_v201_submit_request_must_support_requestor
          test from: :pas_server_v201_submit_request_must_support_beneficiary
          test from: :pas_server_v201_submit_request_must_support_subscriber
          test from: :pas_server_v201_submit_request_must_support_practitioner
          test from: :pas_server_v201_submit_request_must_support_practitioner_role
        end

        group do
          title '$submit Response Must Support'
          test from: :pas_server_v201_submit_response_must_support_pas_response_bundle
          test from: :pas_server_v201_submit_response_must_support_claimresponse
          test from: :pas_server_v201_submit_response_must_support_communication_request
          test from: :pas_server_v201_submit_response_must_support_insurer
          test from: :pas_server_v201_submit_response_must_support_requestor
          test from: :pas_server_v201_submit_response_must_support_beneficiary
          test from: :pas_server_v201_submit_response_must_support_practitioner
          test from: :pas_server_v201_submit_response_must_support_practitioner_role
          test from: :pas_server_v201_submit_response_must_support_task
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
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
          
          
          
          For `$inquire` responses, this includes the following profiles (NOTE: request-specific
          profiles that may be echoed from `$inquire` requests, such as the Claim instance or request instances,
          are not currently checked):
          
          - [PAS Inquiry Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-response-bundle.html)
          - [PAS Claim Inquiry Response](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claiminquiryresponse.html)
          - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
          - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
          - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
          - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
          - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
          - [PAS Task](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html)
          
          
          
        )
        run_as_group

        group do
          title 'Submission of claims to the $inquire operation for must support validation'

          test from: :pas_server_request_bundle_validation_test do
            id :pas_server_v201_inquire_request_bundle_validation_test_must_support
            title '[USER INPUT VALIDATION] Provided $inquire Request Bundle is conformant'
            description %(
              **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
            Errors encountered will be treated as a skip instead of a failure.
            
            This test validates the conformity of the
            user input to the
            [PAS Inquiry Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-request-bundle.html)
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
                  name: :must_support_pa_inquire_request_payload ,
                  title: 'Additional $inquire Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              },
              options: {
                operation: 'inquire',
                use_case: 'must_support',
                ig_version: 'v2.0.1'
              }
            )
          end
          test from: :pas_claim_inquire_operation_test do
            id :pas_v201_claim_inquire_operation_test_must_support
            config(
              inputs: {
                pa_inquire_request_payload: {
                  name: :must_support_pa_inquire_request_payload,
                  title: 'Additional $inquire Request Payloads',
                  description: 'Insert an additional request bundle or a list of bundles (e.g. [bundle_1, bundle_2])'
                }
              },
              options: {
                use_case: 'must_support',
                ig_version: 'v2.0.1'
              }
            )
          end
          test from: :pas_server_response_bundle_validation_test do
            id :pas_server_v201_inquire_response_bundle_validation_test_must_support
            title 'Server $inquire Response Bundle is conformant'
            description %(
              This test validates the conformity of the
              server's response to the
              [PAS Inquiry Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-response-bundle.html)
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
                use_case: 'must_support',
                operation: 'inquire',
                ig_version: 'v2.0.1'
              }
            )
          end
        end

        group do
          title '[USER INPUT VALIDATION] $inquire Request Must Support'
          verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@36'

          test from: :pas_server_v201_inquire_request_must_support_pas_inquiry_request_bundle
          test from: :pas_server_v201_inquire_request_must_support_claim_inquiry
          test from: :pas_server_v201_inquire_request_must_support_coverage
          test from: :pas_server_v201_inquire_request_must_support_insurer
          test from: :pas_server_v201_inquire_request_must_support_requestor
          test from: :pas_server_v201_inquire_request_must_support_beneficiary
          test from: :pas_server_v201_inquire_request_must_support_subscriber
          test from: :pas_server_v201_inquire_request_must_support_practitioner
          test from: :pas_server_v201_inquire_request_must_support_practitioner_role
        end

        group do
          title '$inquire Response Must Support'
          test from: :pas_server_v201_inquire_response_must_support_pas_inquiry_response_bundle
          test from: :pas_server_v201_inquire_response_must_support_claiminquiryresponse
          test from: :pas_server_v201_inquire_response_must_support_insurer
          test from: :pas_server_v201_inquire_response_must_support_requestor
          test from: :pas_server_v201_inquire_response_must_support_beneficiary
          test from: :pas_server_v201_inquire_response_must_support_practitioner
          test from: :pas_server_v201_inquire_response_must_support_practitioner_role
          test from: :pas_server_v201_inquire_response_must_support_task
        end
      end
    end
  end
end
