require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../../endpoints/mock_udap_smart_server'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientUDAPTokenUseTest < Inferno::Test
      include URLs

      id :pas_client_v201_udap_token_use_test
      title 'Verify UDAP Token Use'
      description %(
        Check that a UDAP token returne to the client was used for request
        authentication.
      )

      input :client_id,
            optional: true

      run do
        omit_if client_id.blank?, 'Auth not demonstrated as a part of this test session.'

        token_requests = load_tagged_requests([TOKEN_TAG])
        prior_auth_requests = load_tagged_requests([SUBMIT_TAG]) + load_tagged_requests([INQUIRE_TAG])

        skip_if token_requests.blank?, 'No token requests made.'
        skip_if prior_auth_requests.blank?, 'No prior authorization requests made.'

        used_tokens = prior_auth_requests.map do |authed_request|
          authed_request.request_headers.find do |header|
            header.name.downcase == 'authorization'
          end&.value&.delete_prefix('Bearer ')
        end.compact

        request_with_used_token = token_requests.find do |token_request|
          used_tokens.include?(JSON.parse(token_request.response_body)&.dig('access_token'))
        end

        assert request_with_used_token.present?, 'Returned tokens never used in any requests.'
      end
    end
  end
end
