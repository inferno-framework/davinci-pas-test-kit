require_relative '../../../urls'
require_relative '../../../endpoints/mock_udap_server'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientRequestAuthVerificationTest < Inferno::Test
      include URLs

      id :pas_client_v201_request_auth_verification_test
      title 'Verify Request Authorization Header'
      description %(
        If the tester is providing a bearer token with the request, then this test
        will verify that the token is appropriate for use, e.g., it is not expired.
        Otherwise, the test will be omitted.
      )
      input :client_id,
            optional: true

      run do
        omit_if client_id.blank?, 'Auth not demonstrated as a part of this test session.'

        auth_header = request.request_headers.find { |header| header.name.downcase == 'authorization' }
        token = auth_header&.value&.delete_prefix('Bearer ')
        decoded_token = MockUdapServer.decode_token(token)

        expiration_epoch = decoded_token&.dig('expiration')
        assert Time.now.to_i < expiration_epoch, 'Token has expired.'
      end
    end
  end
end
