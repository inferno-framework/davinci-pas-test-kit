require_relative 'pas_response_bundle/client_submit_response_must_support_pas_response_bundle_test'
require_relative 'claimresponse/client_submit_response_must_support_claimresponse_test'
require_relative 'task/client_submit_response_must_support_task_test'
require_relative 'beneficiary/client_submit_response_must_support_beneficiary_test'
require_relative 'requestor/client_submit_response_must_support_requestor_test'
require_relative 'insurer/client_submit_response_must_support_insurer_test'
require_relative 'practitioner/client_submit_response_must_support_practitioner_test'
require_relative 'practitioner_role/client_submit_response_must_support_practitioner_role_test'
require_relative 'communication_request/client_submit_response_must_support_communication_request_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientSubmitResponseMustSupportGroup < Inferno::TestGroup
      id :pas_client_v220_submit_response_must_support
      title 'Submit Response Must Support'
      description %(
        Check that `$submit` responses provided to the client contain
        all PAS-defined profiles and their must support elements.
        
        **USER INPUT VALIDATION**: These tests validate responses provided by the tester,
        not the system under test. Errors will be treated as skips instead of failures.
        
        For `$submit` responses, this includes the following profiles:
        
        - [PAS Response Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-response-bundle.html)
        - [PAS Claim Response](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claimresponse.html)
        - [PAS Task](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html)
        - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
        - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
        - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
        - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
        - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
        - [PAS CommunicationRequest](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-communicationrequest.html)
        
        
        
      )
      run_as_group
      
      test from: :pas_client_v220_submit_response_must_support_pas_response_bundle
      test from: :pas_client_v220_submit_response_must_support_claimresponse
      test from: :pas_client_v220_submit_response_must_support_task
      test from: :pas_client_v220_submit_response_must_support_beneficiary
      test from: :pas_client_v220_submit_response_must_support_requestor
      test from: :pas_client_v220_submit_response_must_support_insurer
      test from: :pas_client_v220_submit_response_must_support_practitioner
      test from: :pas_client_v220_submit_response_must_support_practitioner_role
      test from: :pas_client_v220_submit_response_must_support_communication_request
    end
  end
end