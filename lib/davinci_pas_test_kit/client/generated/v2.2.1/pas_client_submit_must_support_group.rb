require_relative '../../v2.2.1/must_support/must_support_with_attestation_option'
require_relative 'claim_update/client_submit_request_must_support_claim_update_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubmitMustSupportGroup < Inferno::TestGroup
      id :pas_client_v221_submit_must_support
      title '$submit Request Must Support Coverage'
      description %(
        Check that the client can demonstrate `$submit` requests that contain
        all PAS-defined profiles and their must support elements.
        
        For `$submit` requests, this includes the following profiles:
        
        - [PAS Request Bundle](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-pas-request-bundle.html)
        - [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-claim-update.html)
        - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-coverage.html)
        - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-encounter.html)
        - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-insurer.html)
        - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-requestor.html)
        - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-beneficiary.html)
        - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-subscriber.html)
        - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-practitioner.html)
        - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-practitionerrole.html)
        - At least one of the following request profiles
          - [PAS Device Request](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-devicerequest.html)
          - [PAS Medication Request](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-medicationrequest.html)
          - [PAS Nutrition Order](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-nutritionorder.html)
          - [PAS Service Request](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-servicerequest.html)
        
        
        
      )
      run_as_group
      
      # At least one of the PAS request profiles must be present; unobserved must support
      # elements on the request profiles that are present may be attested as not collected.
      test from: :pas_client_v221_must_support_with_attestation_option do
        id :pas_client_v221_submit_request_profiles_must_support_with_attestation_option
        title 'At least one instance of a request profile (PAS Medication Request, PAS Service Request, PAS Device Request, or PAS Nutrition Order) is observed with all of its must support elements'
        config(
          options: {
            require_one_of: true,
            profiles: [
              { resource_type: 'DeviceRequest', profile_key: 'device_request', title: 'PAS Device Request' },
              { resource_type: 'MedicationRequest', profile_key: 'medication_request', title: 'PAS Medication Request' },
              { resource_type: 'NutritionOrder', profile_key: 'nutrition_order', title: 'PAS Nutrition Order' },
              { resource_type: 'ServiceRequest', profile_key: 'service_request', title: 'PAS Service Request' }
            ],
            ig_version: 'v2.2.1',
            type: 'request',
            operation: 'submit'
          }
        )
        description MustSupportWithAttestationOption.build_description(config.options)
      end

      # Mandatory - the PAS Claim Update profile must always be demonstrated.
      test from: :pas_client_v221_submit_request_must_support_claim_update

      # All other submit request profiles - unobserved must support elements may be
      # attested as not collected by the client system.
      test from: :pas_client_v221_must_support_with_attestation_option do
        id :pas_client_v221_submit_request_other_must_support_with_attestation_option
        title 'All must support elements for other profiles referenced by Claim submissions are observed on $submit requests'
        config(
          options: {
            require_one_of: false,
            profiles: [
              { resource_type: 'Bundle', profile_key: 'pas_request_bundle', title: 'PAS Request Bundle' },
              { resource_type: 'Coverage', profile_key: 'coverage', title: 'PAS Coverage' },
              { resource_type: 'Encounter', profile_key: 'encounter', title: 'PAS Encounter' },
              { resource_type: 'Organization', profile_key: 'insurer', title: 'PAS Insurer Organization' },
              { resource_type: 'Organization', profile_key: 'requestor', title: 'PAS Requestor Organization' },
              { resource_type: 'Patient', profile_key: 'beneficiary', title: 'PAS Beneficiary Patient' },
              { resource_type: 'Patient', profile_key: 'subscriber', title: 'PAS Subscriber Patient' },
              { resource_type: 'Practitioner', profile_key: 'practitioner', title: 'PAS Practitioner' },
              { resource_type: 'PractitionerRole', profile_key: 'practitioner_role', title: 'PAS PractitionerRole' }
            ],
            ig_version: 'v2.2.1',
            type: 'request',
            operation: 'submit'
          }
        )
        description MustSupportWithAttestationOption.build_description(config.options)
      end
    end
  end
end
