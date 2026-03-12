require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitResponseMustSupportClaimresponseTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v201_submit_response_must_support_claimresponse
      title 'All must support elements for Profile PAS Claim Response are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Claim Response Profile.
        This test checks all identified instances of the PAS Claim Response
        Profile on responses sent to the client to ensure that the following
        must support elements are observed:

        * ClaimResponse.communicationRequest
        * ClaimResponse.created
        * ClaimResponse.error
        * ClaimResponse.error.code
        * ClaimResponse.error.extension:errorElement
        * ClaimResponse.error.extension:errorPath
        * ClaimResponse.error.extension:followupAction
        * ClaimResponse.identifier
        * ClaimResponse.insurer
        * ClaimResponse.item
        * ClaimResponse.item.adjudication
        * ClaimResponse.item.adjudication.extension:reviewAction
        * ClaimResponse.item.extension:administrationReferenceNumber
        * ClaimResponse.item.extension:authorizedItemDetail
        * ClaimResponse.item.extension:authorizedProvider
        * ClaimResponse.item.extension:communicatedDiagnosis
        * ClaimResponse.item.extension:itemTraceNumber
        * ClaimResponse.item.extension:preAuthIssueDate
        * ClaimResponse.item.extension:preAuthPeriod
        * ClaimResponse.item.extension:previousAuthorizationNumber
        * ClaimResponse.item.extension:requestedServiceDate
        * ClaimResponse.item.noteNumber
        * ClaimResponse.outcome
        * ClaimResponse.patient
        * ClaimResponse.preAuthPeriod
        * ClaimResponse.request
        * ClaimResponse.requestor
        * ClaimResponse.status
      )

      config(
        options: {
          resource_type: 'ClaimResponse',
          profile_key: 'claimresponse',
          user_input_validation: true,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end