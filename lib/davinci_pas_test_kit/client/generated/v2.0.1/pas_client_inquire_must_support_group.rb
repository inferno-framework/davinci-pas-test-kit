require_relative '../../v2.0.1/must_support/pas_client_inquire_gather_must_support_test'
require_relative 'pas_inquiry_request_bundle/client_inquire_request_must_support_pas_inquiry_request_bundle_test'
require_relative 'claim_inquiry/client_inquire_request_must_support_claim_inquiry_test'
require_relative 'coverage/client_inquire_request_must_support_coverage_test'
require_relative 'insurer/client_inquire_request_must_support_insurer_test'
require_relative 'requestor/client_inquire_request_must_support_requestor_test'
require_relative 'beneficiary/client_inquire_request_must_support_beneficiary_test'
require_relative 'subscriber/client_inquire_request_must_support_subscriber_test'
require_relative 'practitioner/client_inquire_request_must_support_practitioner_test'
require_relative 'practitioner_role/client_inquire_request_must_support_practitioner_role_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientInquireMustSupportGroup < Inferno::TestGroup
      id :pas_client_v201_inquire_must_support
      title 'Inquiry Request Must Support'
      description %(
        Check that the client can demonstrate `$inquire` requests that contain
        all PAS-defined profiles and their must support elements.
        
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
        
        
        
      )
      run_as_group
      
      test from: :pas_client_v201_inquire_gather_must_support
      test from: :pas_client_v201_inquire_request_must_support_pas_inquiry_request_bundle
      test from: :pas_client_v201_inquire_request_must_support_claim_inquiry
      test from: :pas_client_v201_inquire_request_must_support_coverage
      test from: :pas_client_v201_inquire_request_must_support_insurer
      test from: :pas_client_v201_inquire_request_must_support_requestor
      test from: :pas_client_v201_inquire_request_must_support_beneficiary
      test from: :pas_client_v201_inquire_request_must_support_subscriber
      test from: :pas_client_v201_inquire_request_must_support_practitioner
      test from: :pas_client_v201_inquire_request_must_support_practitioner_role
    end
  end
end
