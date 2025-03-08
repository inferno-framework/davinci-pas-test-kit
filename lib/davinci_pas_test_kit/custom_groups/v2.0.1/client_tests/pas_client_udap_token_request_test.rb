require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../../endpoints/mock_udap_smart_server'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientUDAPTokenRequestTest < Inferno::Test
      include URLs

      id :pas_client_v201_udap_token_request_test
      title 'Verify UDAP Token Requests'
      description %(
        Check that UDAP token requests are conformant.
      )

      input :client_id,
            optional: true,
            locked: true

      run do
        omit_if client_id.blank?, 'Auth not demonstrated as a part of this test session.'

        load_tagged_requests(TOKEN_TAG, UDAP_TAG)

        skip_if requests.blank?, 'No UDAP token requests made.'

        requests.each_with_index do |token_request, index|
          assert_valid_json(token_request.request_body)
          token_request_body = JSON.parse(token_request.request_body)
          next unless token_request_body['grant_type'] != 'client_credentials'

          add_message('error',
                      "Token request #{index} had an incorrect `grant_type`: expected 'client_credentials', " \
                      "but got '#{token_request_body['grant_type']}'")
        end

        assert messages.none? { |msg|
          msg[:type] == 'error'
        }, 'Invalid token requests detected. See messages for details.'
      end
    end
  end
end
