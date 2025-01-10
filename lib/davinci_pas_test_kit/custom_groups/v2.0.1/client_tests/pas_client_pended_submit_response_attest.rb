require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedSubmitResponseAttest < Inferno::Test
      include URLs

      id :pas_client_v201_pended_submit_response_attest
      title 'Check that the client registers the request as pended (Attestation)'
      description %(
        This test provides the tester an opportunity to observe their client following
        the receipt of the pended response and attest that users are able to determine
        that the response has been pended and a decision will be forth coming.
      )
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )

      run do
        load_tagged_requests(PENDED_WORKFLOW_TAG, SUBMIT_TAG)
        skip_if requests.empty?, 'No submit requests made.'
        wait(
          identifier: access_token,
          message: %(
            **Pended Workflow Test**:

            I attest that following the receipt of the 'pended' response to the submitted claim,
            the client system indicates to users that a final decision on request has not yet
            been made.

            [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

            [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
          )
        )
      end
    end
  end
end
