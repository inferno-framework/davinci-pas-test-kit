require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientTokenRequestTest < Inferno::Test
      include URLs

      id :pas_client_v201_token_request_test
      title 'Client makes token request'
      description %(
        Inferno will wait for the client to make a token request.
      )
      input :client_id,
            title: 'Client ID',
            description: %(
              Client ID that the client will use to request an access token.
            )

      run do
        wait(
          identifier: client_id,
          message: %(
            Submit your token request with client id `#{client_id}` to

            `#{token_url}`
          )
        )
      end
    end
  end
end
