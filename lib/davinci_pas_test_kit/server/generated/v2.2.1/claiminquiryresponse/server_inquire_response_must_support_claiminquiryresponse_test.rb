require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ServerInquireResponseMustSupportClaiminquiryresponseTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v221_inquire_response_must_support_claiminquiryresponse
      title 'All must support elements for Profile PAS Claim Inquiry Response are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Claim Inquiry Response Profile.
        This test checks all identified instances of the PAS Claim Inquiry Response
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * ClaimResponse.addItem
        * ClaimResponse.addItem.adjudication
        * ClaimResponse.addItem.adjudication.extension:reviewAction
        * ClaimResponse.addItem.extension:administrationReferenceNumber
        * ClaimResponse.addItem.extension:admissionDates
        * ClaimResponse.addItem.extension:certificationType
        * ClaimResponse.addItem.extension:dischargeDate
        * ClaimResponse.addItem.extension:epsdtIndicator
        * ClaimResponse.addItem.extension:itemTraceNumber
        * ClaimResponse.addItem.extension:nursingHomeLevelOfCare
        * ClaimResponse.addItem.extension:nursingHomeResidentialStatus
        * ClaimResponse.addItem.extension:preAuthIssueDate
        * ClaimResponse.addItem.extension:preAuthPeriod
        * ClaimResponse.addItem.extension:previousAuthorizationNumber
        * ClaimResponse.addItem.extension:productOrServiceCodeEnd
        * ClaimResponse.addItem.extension:requestType
        * ClaimResponse.addItem.extension:requestedService
        * ClaimResponse.addItem.extension:revenue
        * ClaimResponse.addItem.extension:revenueUnitRateLimit
        * ClaimResponse.addItem.itemSequence
        * ClaimResponse.addItem.location[x]
        * ClaimResponse.addItem.modifier
        * ClaimResponse.addItem.productOrService
        * ClaimResponse.addItem.provider
        * ClaimResponse.addItem.provider.extension:providerType
        * ClaimResponse.addItem.quantity
        * ClaimResponse.addItem.serviced[x]
        * ClaimResponse.addItem.unitPrice
        * ClaimResponse.adjudication
        * ClaimResponse.adjudication.extension:reviewAction
        * ClaimResponse.created
        * ClaimResponse.error
        * ClaimResponse.error.code
        * ClaimResponse.error.extension:errorElement
        * ClaimResponse.error.extension:errorPath
        * ClaimResponse.error.extension:followupAction
        * ClaimResponse.extension:authorizedProvider
        * ClaimResponse.extension:claimResponseReviewer
        * ClaimResponse.extension:transmissionIdentifiers
        * ClaimResponse.identifier
        * ClaimResponse.identifier.extension:jurisdiction
        * ClaimResponse.identifier.extension:subDepartment
        * ClaimResponse.identifier.system
        * ClaimResponse.identifier.value
        * ClaimResponse.insurer
        * ClaimResponse.item
        * ClaimResponse.item.adjudication
        * ClaimResponse.item.adjudication.extension:reviewAction
        * ClaimResponse.item.extension:administrationReferenceNumber
        * ClaimResponse.item.extension:admissionDates
        * ClaimResponse.item.extension:authorizedItemDetail
        * ClaimResponse.item.extension:authorizedProvider
        * ClaimResponse.item.extension:communicatedDiagnosis
        * ClaimResponse.item.extension:dischargeDate
        * ClaimResponse.item.extension:itemTraceNumber
        * ClaimResponse.item.extension:preAuthIssueDate
        * ClaimResponse.item.extension:preAuthPeriod
        * ClaimResponse.item.extension:previousAuthorizationNumber
        * ClaimResponse.item.extension:requestedServiceDate
        * ClaimResponse.item.itemSequence
        * ClaimResponse.item.noteNumber
        * ClaimResponse.outcome
        * ClaimResponse.patient
        * ClaimResponse.preAuthPeriod
        * ClaimResponse.processNote
        * ClaimResponse.processNote.number
        * ClaimResponse.processNote.text
        * ClaimResponse.request
        * ClaimResponse.request.extension:DataAbsentReason
        * ClaimResponse.requestor
        * ClaimResponse.status
      )

      config(
        options: {
          resource_type: 'ClaimResponse',
          profile_key: 'claiminquiryresponse',
          user_input_validation: false,
          ig_version: 'v2.2.1',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
