require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientApprovalSubmitTest < Inferno::Test
      include URLs

      id :pas_client_v201_approval_submit_test
      title 'Client submits a claim using the $submit operation'
      description %(
        Inferno will wait for a prior authorization submission request
        from the client. Upon receipt, Inferno will generate and send a
        response with an approved status.
      )
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )
      submit_respond_with :approval_json_response

      run do
        wait(
          identifier: access_token,
          message: %(
            **Approval Workflow Test**:

            Submit a PAS request to

            `#{submit_url}`

            If the optional '**#{input_title(:approval_json_response)}**' input is populated, it will
            be returned, updated with current timestamps. Otherwise, an approval response will
            be generated by Inferno using the received Claim.
          )
        )
      end
    end
  end
end
