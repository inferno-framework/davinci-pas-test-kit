require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientTokentRequestTest < Inferno::Test
      id :pas_client_v201_token_validation_test
      title 'Client token request is valid'
      description 'Inferno will verify that an access token was successfully returned to the client under test.'
      output :access_token

      run do
        load_tagged_requests(AUTH_TAG)
        skip_if requests.empty?, 'No token requests were received'
        output access_token: JSON.parse(requests.last.response_body)['access_token']
      end
    end
  end
end
