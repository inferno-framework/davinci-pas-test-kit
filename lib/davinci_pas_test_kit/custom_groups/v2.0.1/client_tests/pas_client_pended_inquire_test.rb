require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientPendedInquireTest < Inferno::Test
      include URLs

      id :pas_client_v201_pended_inquire_test
      title 'Client inquires about a pended claim using the $inquire operation'
      description %(
        Inferno will wait for a prior authorization inquiry request
        from the client. Upon receipt, Inferno will generate a response
        with an approved status and respond with it.
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

            Submit a PAS claim inquiry request for the pended prior authorization request to `#{inquire_url}`.
            An approval response generated by Inferno will be returned.
          )
        )
      end
    end
  end
end
