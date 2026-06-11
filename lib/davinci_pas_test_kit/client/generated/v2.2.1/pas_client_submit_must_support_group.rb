require_relative '../../v2.2.1/must_support/pas_client_must_support_request_profiles_test'
require_relative 'pas_request_bundle/client_submit_request_must_support_pas_request_bundle_test'
require_relative 'claim_update/client_submit_request_must_support_claim_update_test'
require_relative 'coverage/client_submit_request_must_support_coverage_test'
require_relative 'encounter/client_submit_request_must_support_encounter_test'
require_relative 'insurer/client_submit_request_must_support_insurer_test'
require_relative 'requestor/client_submit_request_must_support_requestor_test'
require_relative 'beneficiary/client_submit_request_must_support_beneficiary_test'
require_relative 'subscriber/client_submit_request_must_support_subscriber_test'
require_relative 'practitioner/client_submit_request_must_support_practitioner_test'
require_relative 'practitioner_role/client_submit_request_must_support_practitioner_role_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubmitMustSupportGroup < Inferno::TestGroup
      id :pas_client_v221_submit_must_support
      title 'Submit Request Must Support'
      description %(
        Check that the client can demonstrate `$submit` requests that contain
        all PAS-defined profiles and their must support elements.
        
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
        
        
        
      )
      run_as_group

      test from: :pas_client_v221_must_support_request_profiles do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_pas_request_bundle do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_claim_update
      test from: :pas_client_v221_submit_request_must_support_coverage do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_encounter do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_insurer do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_requestor do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_beneficiary do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_subscriber do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_practitioner do
        optional
      end
      test from: :pas_client_v221_submit_request_must_support_practitioner_role do
        optional
      end
    end
  end
end
