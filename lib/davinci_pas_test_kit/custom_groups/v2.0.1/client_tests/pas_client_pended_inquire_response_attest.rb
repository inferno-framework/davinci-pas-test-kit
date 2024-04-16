require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedInquireResponseAttest < Inferno::Test
      include URLs

      id :pas_client_v201_pended_inquire_response_attest
      title 'Check that the client registers the request as approved (Attestation)'
      description %(
        This test provides the tester an opportunity to observe their client following
        the receipt of the inquiry response with a final decision and attest that users
        are able to determine that the response has been approved in full.
      )
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )

      run do
        wait(
          identifier: access_token,
          message: %(
            **Pended Workflow Test**:

            I attest that the client system displays the submitted claim as 'approved' meaning that
            the user can proceed with ordering or providing the requested service.

            [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

            [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
          )
        )
      end
    end
  end
end
