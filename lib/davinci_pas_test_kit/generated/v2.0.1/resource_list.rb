module DaVinciPASTestKit
    module PASV201
      module ResourceList
        RESOURCE_LIST = [
          'Inquiry Request Bundle',
          'Inquiry Response Bundle',
          'Request Bundle',
          'Response Bundle',
          'Claim Base',
          'Claim Inquiry',
          'Claim Update',
          'Claim',
          'Claim Inquiry Response',
          'Claim Response Base',
          'Claim Response',
          'CommunicationRequest',
          'Coverage',
          'Device Request',
          'Encounter',
          'Location',
          'Medication Request',
          'Nutrition Order',
          'Insurer Organization',
          'Organization Base',
          'Requestor Organization',
          'Beneficiary Patient',
          'Subscriber Patient',
          'Practitioner',
          'PractitionerRole',
          'Service Request',
          'Task'
        ].freeze

        RESOURCE_SUPPORTED_PROFILES = {
          Bundle: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-response-bundle", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle"],
          Claim: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim-base", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim-inquiry", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim-update", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim"],
          ClaimResponse: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claiminquiryresponse", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claimresponse-base", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claimresponse"],
          CommunicationRequest: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-communicationrequest"],
          Coverage: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-coverage"],
          DeviceRequest: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-devicerequest"],
          Encounter: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter"],
          Location: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-location"],
          MedicationRequest: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-medicationrequest"],
          NutritionOrder: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-nutritionorder"],
          Organization: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-insurer", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-organization", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-requestor"],
          Patient: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-beneficiary", "http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-subscriber"],
          Practitioner: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-practitioner"],
          PractitionerRole: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-practitionerrole"],
          ServiceRequest: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-servicerequest"],
          Task: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-task"],
        }.freeze
      end
    end
end
