require_relative 'pas_inquiry_request_bundle/client_inquiry_request_pas_inquiry_request_bundle_must_support_test'
require_relative 'claim_inquiry/client_inquiry_request_claim_inquiry_must_support_test'
require_relative 'coverage/client_inquiry_request_coverage_must_support_test'
require_relative 'insurer/client_inquiry_request_insurer_must_support_test'
require_relative 'requestor/client_inquiry_request_requestor_must_support_test'
require_relative 'beneficiary/client_inquiry_request_beneficiary_must_support_test'
require_relative 'subscriber/client_inquiry_request_subscriber_must_support_test'
require_relative 'practitioner/client_inquiry_request_practitioner_must_support_test'
require_relative 'practitioner_role/client_inquiry_request_practitioner_role_must_support_test'
require_relative '../../custom_groups/v2.0.1/client_tests/pas_client_inquire_must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientInquiryMustSupportUseCaseGroup < Inferno::TestGroup
      title 'Inquiry Request Must Support'
      description %(
        Check that the client can demonstrate `$inquire` requests that contain
        all PAS-defined profiles and their must support elements.
        
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
        
      )

      id :pas_client_v201_inquiry_must_support_use_case
      run_as_group
  
    
      test from: :pas_client_inquire_v201_must_support_test
      test from: :pas_client_inquiry_request_v201_pas_inquiry_request_bundle_must_support_test
      test from: :pas_client_inquiry_request_v201_claim_inquiry_must_support_test
      test from: :pas_client_inquiry_request_v201_coverage_must_support_test
      test from: :pas_client_inquiry_request_v201_insurer_must_support_test
      test from: :pas_client_inquiry_request_v201_requestor_must_support_test
      test from: :pas_client_inquiry_request_v201_beneficiary_must_support_test
      test from: :pas_client_inquiry_request_v201_subscriber_must_support_test
      test from: :pas_client_inquiry_request_v201_practitioner_must_support_test
      test from: :pas_client_inquiry_request_v201_practitioner_role_must_support_test
  
    end
  end
end
