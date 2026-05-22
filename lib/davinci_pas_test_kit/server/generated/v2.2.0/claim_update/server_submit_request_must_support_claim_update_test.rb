require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ServerSubmitRequestMustSupportClaimUpdateTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v220_submit_request_must_support_claim_update
      title 'All must support elements for Profile PAS Claim Update are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Claim Update Profile.
        This test checks all identified instances of the PAS Claim Update
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * Claim.accident
        * Claim.accident.date
        * Claim.accident.location[x]
        * Claim.accident.type
        * Claim.careTeam
        * Claim.careTeam.extension:careTeamClaimScope
        * Claim.careTeam.provider
        * Claim.careTeam.qualification
        * Claim.careTeam.role
        * Claim.careTeam.sequence
        * Claim.careTeam:ItemClaimMember
        * Claim.careTeam:ItemClaimMember.extension:careTeamClaimScope
        * Claim.careTeam:ItemClaimMember.extension:careTeamClaimScope.value[x]
        * Claim.careTeam:ItemClaimMember.provider
        * Claim.careTeam:ItemClaimMember.qualification
        * Claim.careTeam:ItemClaimMember.role
        * Claim.careTeam:ItemClaimMember.sequence
        * Claim.careTeam:OverallClaimMember
        * Claim.careTeam:OverallClaimMember.extension:careTeamClaimScope
        * Claim.careTeam:OverallClaimMember.extension:careTeamClaimScope.value[x]
        * Claim.careTeam:OverallClaimMember.provider
        * Claim.careTeam:OverallClaimMember.qualification
        * Claim.careTeam:OverallClaimMember.role
        * Claim.careTeam:OverallClaimMember.sequence
        * Claim.diagnosis
        * Claim.diagnosis.diagnosis[x]
        * Claim.diagnosis.extension:recordedDate
        * Claim.diagnosis.sequence
        * Claim.diagnosis.type
        * Claim.extension:administrationReferenceNumber
        * Claim.extension:authorizationNumber
        * Claim.extension:certificationType
        * Claim.extension:conditionCode
        * Claim.extension:encounter
        * Claim.extension:homeHealthCareInformation
        * Claim.extension:levelOfServiceType
        * Claim.extension:transmissionIdentifiers
        * Claim.identifier
        * Claim.identifier.extension:jurisdiction
        * Claim.identifier.extension:subDepartment
        * Claim.identifier.system
        * Claim.identifier.value
        * Claim.insurance
        * Claim.insurance.coverage
        * Claim.insurance.sequence
        * Claim.insurer
        * Claim.item
        * Claim.item.careTeamSequence
        * Claim.item.category
        * Claim.item.diagnosisSequence
        * Claim.item.extension:administrationReferenceNumber
        * Claim.item.extension:authorizationNumber
        * Claim.item.extension:certificationType
        * Claim.item.extension:epsdtIndicator
        * Claim.item.extension:infoChanged
        * Claim.item.extension:itemTraceNumber
        * Claim.item.extension:nursingHomeLevelOfCare
        * Claim.item.extension:nursingHomeResidentialStatus
        * Claim.item.extension:nursingHomeResidentialStatus.value[x]
        * Claim.item.extension:productOrServiceCodeEnd
        * Claim.item.extension:requestType
        * Claim.item.extension:requestedService
        * Claim.item.extension:revenueUnitRateLimit
        * Claim.item.informationSequence
        * Claim.item.location[x]
        * Claim.item.modifier
        * Claim.item.modifierExtension:infoCancelledFlag
        * Claim.item.productOrService
        * Claim.item.quantity
        * Claim.item.revenue
        * Claim.item.sequence
        * Claim.item.serviced[x]
        * Claim.item.serviced[x]:servicedDate
        * Claim.item.serviced[x]:servicedPeriod
        * Claim.item.unitPrice
        * Claim.patient
        * Claim.provider
        * Claim.related
        * Claim.related.claim
        * Claim.related.relationship.coding.code
        * Claim.status
        * Claim.supportingInfo
        * Claim.supportingInfo.category
        * Claim.supportingInfo.extension:infoChanged
        * Claim.supportingInfo.modifierExtension:infoCancelledFlag
        * Claim.supportingInfo.sequence
        * Claim.supportingInfo:AdditionalInformation
        * Claim.supportingInfo:AdditionalInformation.category
        * Claim.supportingInfo:AdditionalInformation.extension:documentInformation
        * Claim.supportingInfo:AdditionalInformation.sequence
        * Claim.supportingInfo:AdditionalInformation.value[x]
        * Claim.supportingInfo:AdmissionDates
        * Claim.supportingInfo:AdmissionDates.category
        * Claim.supportingInfo:AdmissionDates.sequence
        * Claim.supportingInfo:AdmissionDates.timing[x]
        * Claim.supportingInfo:AdmissionDates.timing[x]:timingPeriod
        * Claim.supportingInfo:AdmissionDates.timing[x]:timingPeriod.end
        * Claim.supportingInfo:AdmissionDates.timing[x]:timingPeriod.start
        * Claim.supportingInfo:DischargeDates
        * Claim.supportingInfo:DischargeDates.category
        * Claim.supportingInfo:DischargeDates.sequence
        * Claim.supportingInfo:DischargeDates.timing[x]
        * Claim.supportingInfo:MessageText
        * Claim.supportingInfo:MessageText.category
        * Claim.supportingInfo:MessageText.sequence
        * Claim.supportingInfo:MessageText.value[x]
        * Claim.supportingInfo:PatientEvent
        * Claim.supportingInfo:PatientEvent.category
        * Claim.supportingInfo:PatientEvent.sequence
        * Claim.supportingInfo:PatientEvent.timing[x]
        * Claim.supportingInfo:PatientEvent.timing[x]:timingPeriod
        * Claim.supportingInfo:PatientEvent.timing[x]:timingPeriod.end
        * Claim.supportingInfo:PatientEvent.timing[x]:timingPeriod.start
        * Claim.use
      )

      config(
        options: {
          resource_type: 'Claim',
          profile_key: 'claim_update',
          user_input_validation: true,
          ig_version: 'v2.2.0',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end
end
