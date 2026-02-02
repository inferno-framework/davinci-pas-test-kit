require_relative '../../pas_client_submit_gather_must_support_test'
require_relative '../../v2.2.0/must_support/pas_client_must_support_request_profiles_test'
require_relative 'pas_request_bundle/client_submit_request_must_support_pas_request_bundle_test'
require_relative 'claim_update/client_submit_request_must_support_claim_update_test'
require_relative 'encounter/client_submit_request_must_support_encounter_test'
require_relative 'coverage/client_submit_request_must_support_coverage_test'
require_relative 'beneficiary/client_submit_request_must_support_beneficiary_test'
require_relative 'subscriber/client_submit_request_must_support_subscriber_test'
require_relative 'requestor/client_submit_request_must_support_requestor_test'
require_relative 'insurer/client_submit_request_must_support_insurer_test'
require_relative 'practitioner/client_submit_request_must_support_practitioner_test'
require_relative 'practitioner_role/client_submit_request_must_support_practitioner_role_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientSubmitMustSupportGroup < Inferno::TestGroup
      id :pas_client_v220_submit_must_support
      title 'Submit Request Must Support'
      description %(
        Check that the client can demonstrate `$submit` requests that contain
        all PAS-defined profiles and their must support elements.
        
        For `$submit` requests, this includes the following profiles:
        
        - [PAS Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-request-bundle.html)
        - [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-update.html)
        - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-encounter.html)
        - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-coverage.html)
        - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
        - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
        - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
        - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
        - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
        - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
        - At least one of the following request profiles
          - [PAS Medication Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-medicationrequest.html)
          - [PAS Device Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-devicerequest.html)
          - [PAS Nutrition Order](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-nutritionorder.html)
          - [PAS Service Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-servicerequest.html)
        
        
        
      )
      run_as_group
      
      test from: :pas_client_submit_gather_must_support
      test from: :pas_client_v220_must_support_request_profiles
      test from: :pas_client_v220_submit_request_must_support_pas_request_bundle
      test from: :pas_client_v220_submit_request_must_support_claim_update
      test from: :pas_client_v220_submit_request_must_support_encounter
      test from: :pas_client_v220_submit_request_must_support_coverage
      test from: :pas_client_v220_submit_request_must_support_beneficiary
      test from: :pas_client_v220_submit_request_must_support_subscriber
      test from: :pas_client_v220_submit_request_must_support_requestor
      test from: :pas_client_v220_submit_request_must_support_insurer
      test from: :pas_client_v220_submit_request_must_support_practitioner
      test from: :pas_client_v220_submit_request_must_support_practitioner_role
    end
  end
end
