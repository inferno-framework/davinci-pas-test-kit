require_relative 'pas_inquiry_response_bundle/client_inquire_response_must_support_pas_inquiry_response_bundle_test'
require_relative 'claiminquiryresponse/client_inquire_response_must_support_claiminquiryresponse_test'
require_relative 'insurer/client_inquire_response_must_support_insurer_test'
require_relative 'requestor/client_inquire_response_must_support_requestor_test'
require_relative 'beneficiary/client_inquire_response_must_support_beneficiary_test'
require_relative 'practitioner/client_inquire_response_must_support_practitioner_test'
require_relative 'practitioner_role/client_inquire_response_must_support_practitioner_role_test'
require_relative 'task/client_inquire_response_must_support_task_test'
require_relative '../../v2.2.1/workflows/pas_client_response_attest'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientInquireResponseMustSupportGroup < Inferno::TestGroup
      id :pas_client_v221_inquire_response_must_support
      title '$inquire Response Must Support Coverage'
      description %(
        Check that `$inquire` responses provided to the client contain
        all PAS-defined profiles and their must support elements.
        
        **USER INPUT VALIDATION**: These tests validate responses provided by the tester,
        not the system under test. Errors will be treated as skips instead of failures.
        
        For `$inquire` responses, this includes the following profiles:
        
        - [PAS Inquiry Response Bundle](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-pas-inquiry-response-bundle.html)
        - [PAS Claim Inquiry Response](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-claiminquiryresponse.html)
        - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-insurer.html)
        - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-requestor.html)
        - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-beneficiary.html)
        - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-practitioner.html)
        - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-practitionerrole.html)
        - [PAS Task](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-task.html)
        
        
        
      )
      run_as_group

      test from: :pas_client_v221_inquire_response_must_support_pas_inquiry_response_bundle do
        optional
      end
      test from: :pas_client_v221_inquire_response_must_support_claiminquiryresponse do
        verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@conf-7'
      end
      test from: :pas_client_v221_inquire_response_must_support_insurer do
        optional
      end
      test from: :pas_client_v221_inquire_response_must_support_requestor do
        optional
      end
      test from: :pas_client_v221_inquire_response_must_support_beneficiary do
        optional
      end
      test from: :pas_client_v221_inquire_response_must_support_practitioner do
        optional
      end
      test from: :pas_client_v221_inquire_response_must_support_practitioner_role do
        optional
      end
      test from: :pas_client_v221_inquire_response_must_support_task do
        optional
      end
      test from: :pas_client_v221_response_attest,
           title: 'PAS client handled the $inquire response must support elements',
           description: %(
             This test provides the tester an opportunity to verify that their client
             correctly processed and used the must support elements present in the
             $inquire responses received from Inferno during these tests.
           ),
           config: { options: {
             workflow_tag: MUST_SUPPORT_WORKFLOW_TAG,
             attest_message: "I attest that the client system correctly processed the must support elements " \
                             "contained in the $inquire responses received from Inferno and did not error."
           } } do
        verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@conf-8'
      end
    end
  end
end
