require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ClientInquireRequestMustSupportClaimInquiryTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v220_inquire_request_must_support_claim_inquiry
      title 'All must support elements for Profile PAS Claim Inquiry are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Claim Inquiry Profile.
        This test checks all identified instances of the PAS Claim Inquiry
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * Claim.accident
        * Claim.accident.date
        * Claim.accident.location[x]
        * Claim.accident.type
        * Claim.billablePeriod
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
        * Claim.diagnosis.sequence
        * Claim.diagnosis.type
        * Claim.extension:administrationReferenceNumber
        * Claim.extension:authorizationNumber
        * Claim.extension:certificationType
        * Claim.extension:conditionCode
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
        * Claim.item.extension:certEffectiveDate
        * Claim.item.extension:certExpirationDate
        * Claim.item.extension:certIssueDate
        * Claim.item.extension:certificationType
        * Claim.item.extension:itemTraceNumber
        * Claim.item.extension:productOrServiceCodeEnd
        * Claim.item.extension:requestType
        * Claim.item.extension:reviewActionCode
        * Claim.item.informationSequence
        * Claim.item.location[x]
        * Claim.item.modifier
        * Claim.item.productOrService
        * Claim.item.quantity
        * Claim.item.revenue
        * Claim.item.sequence
        * Claim.item.serviced[x]
        * Claim.item.serviced[x]:servicedDate
        * Claim.item.serviced[x]:servicedPeriod
        * Claim.patient
        * Claim.provider
        * Claim.status
        * Claim.supportingInfo
        * Claim.supportingInfo.category
        * Claim.supportingInfo.sequence
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
          profile_key: 'claim_inquiry',
          user_input_validation: false,
          ig_version: 'v2.2.0',
          type: 'request',
          operation: 'inquire'
        }
      )
    end
  end
end
