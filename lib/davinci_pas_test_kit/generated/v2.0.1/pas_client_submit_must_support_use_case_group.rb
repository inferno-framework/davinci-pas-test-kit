require_relative 'pas_request_bundle/client_submit_request_pas_request_bundle_must_support_test'
require_relative 'claim_update/client_submit_request_claim_update_must_support_test'
require_relative 'coverage/client_submit_request_coverage_must_support_test'
require_relative 'encounter/client_submit_request_encounter_must_support_test'
require_relative 'insurer/client_submit_request_insurer_must_support_test'
require_relative 'requestor/client_submit_request_requestor_must_support_test'
require_relative 'beneficiary/client_submit_request_beneficiary_must_support_test'
require_relative 'subscriber/client_submit_request_subscriber_must_support_test'
require_relative 'practitioner/client_submit_request_practitioner_must_support_test'
require_relative 'practitioner_role/client_submit_request_practitioner_role_must_support_test'
require_relative '../../custom_groups/v2.0.1/must_support/pas_client_must_support_requirement_test'
require_relative '../../custom_groups/v2.0.1/client_tests/pas_client_submit_must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubmitMustSupportUseCaseGroup < Inferno::TestGroup
      title 'Submit Request Must Support'
      description %(
        Check that the client can demonstrate `$submit` requests that contain
        all PAS-defined profiles and their must support elements.
        
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
        
      )

      id :pas_client_v201_submit_must_support_use_case
      run_as_group
  
    
      test from: :pas_client_submit_v201_must_support_test
      test from: :pas_client_submit_v201_must_support_requirement
      test from: :pas_client_submit_request_v201_pas_request_bundle_must_support_test
      test from: :pas_client_submit_request_v201_claim_update_must_support_test
      test from: :pas_client_submit_request_v201_coverage_must_support_test
      test from: :pas_client_submit_request_v201_encounter_must_support_test
      test from: :pas_client_submit_request_v201_insurer_must_support_test
      test from: :pas_client_submit_request_v201_requestor_must_support_test
      test from: :pas_client_submit_request_v201_beneficiary_must_support_test
      test from: :pas_client_submit_request_v201_subscriber_must_support_test
      test from: :pas_client_submit_request_v201_practitioner_must_support_test
      test from: :pas_client_submit_request_v201_practitioner_role_must_support_test
  
    end
  end
end
