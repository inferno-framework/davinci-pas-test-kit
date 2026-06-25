require_relative '../../v2.2.1/must_support/must_support_with_attestation_option'
require_relative 'claim_inquiry/client_inquire_request_must_support_claim_inquiry_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientInquireMustSupportGroup < Inferno::TestGroup
      id :pas_client_v221_inquire_must_support
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
      
      # Mandatory - the PAS Claim Inquiry profile must always be demonstrated.
      test from: :pas_client_v221_inquire_request_must_support_claim_inquiry

      # All other inquire request profiles - unobserved must support elements may be
      # attested as not collected by the client system.
      test from: :pas_client_v221_must_support_with_attestation_option do
        id :pas_client_v221_inquire_request_other_must_support_with_attestation_option
        title 'All other inquire request profile must support elements are observed'
        config(
          options: {
            require_one_of: false,
            profiles: [
              { resource_type: 'Bundle', profile_key: 'pas_inquiry_request_bundle', title: 'PAS Inquiry Request Bundle' },
              { resource_type: 'Coverage', profile_key: 'coverage', title: 'PAS Coverage' },
              { resource_type: 'Organization', profile_key: 'insurer', title: 'PAS Insurer Organization' },
              { resource_type: 'Organization', profile_key: 'requestor', title: 'PAS Requestor Organization' },
              { resource_type: 'Patient', profile_key: 'beneficiary', title: 'PAS Beneficiary Patient' },
              { resource_type: 'Patient', profile_key: 'subscriber', title: 'PAS Subscriber Patient' },
              { resource_type: 'Practitioner', profile_key: 'practitioner', title: 'PAS Practitioner' },
              { resource_type: 'PractitionerRole', profile_key: 'practitioner_role', title: 'PAS PractitionerRole' }
            ],
            ig_version: 'v2.2.1',
            type: 'request',
            operation: 'inquire'
          }
        )
        description MustSupportWithAttestationOption.build_description(config.options)
      end
    end
  end
end
