require_relative 'claim_inquiry/server_claim_inquiry_response_tests'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASServerClaimInquiryResponsesGroup < Inferno::TestGroup
      id :pas_server_v221_claim_inquiry_responses
      title 'Additional $inquire Response Requirements'
      description %(
        Verify additional PAS Claim Inquiry Response rules against the ClaimResponse resources returned
        by prior `$inquire` interactions. This group uses the inquiry responses already collected during
        the server suite, including the Must Support inquiry workflow.
      )

      test from: :pas_server_v221_claim_inquiry_response_claim_reference_test
    end
  end
end
