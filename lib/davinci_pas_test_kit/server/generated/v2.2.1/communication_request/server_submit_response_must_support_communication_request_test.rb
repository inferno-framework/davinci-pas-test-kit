require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ServerSubmitResponseMustSupportCommunicationRequestTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v221_submit_response_must_support_communication_request
      title 'All must support elements for Profile PAS CommunicationRequest are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS CommunicationRequest Profile.
        This test checks all identified instances of the PAS CommunicationRequest
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * CommunicationRequest.category
        * CommunicationRequest.extension:serviceLineNumber
        * CommunicationRequest.identifier
        * CommunicationRequest.medium
        * CommunicationRequest.payload
        * CommunicationRequest.payload.content[x]
        * CommunicationRequest.payload.extension:communicatedDiagnosis
        * CommunicationRequest.payload.extension:contentModifier
        * CommunicationRequest.recipient
        * CommunicationRequest.requester
        * CommunicationRequest.sender
      )

      config(
        options: {
          resource_type: 'CommunicationRequest',
          profile_key: 'communication_request',
          user_input_validation: false,
          ig_version: 'v2.2.1',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end
