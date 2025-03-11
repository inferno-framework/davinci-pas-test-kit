require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../../descriptions'
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
            title: 'Client Id',
            type: 'text',
            optional: true,
            locked: true,
            description: INPUT_CLIENT_ID_LOCKED

      run do
        load_tagged_requests(REGISTRATION_TAG, UDAP_TAG)
        omit_if requests.blank?, 'UDAP Authentication not demonstrated as a part of this test session.'

        requests.clear
        load_tagged_requests(TOKEN_TAG, UDAP_TAG)

        skip_if requests.blank?, 'No UDAP token requests made.'

        requests.each_with_index do |token_request, index|
          request_params = URI.decode_www_form(token_request.request_body).to_h
          next unless request_params['grant_type'] != 'client_credentials'

          add_message('error',
                      "Token request #{index} had an incorrect `grant_type`: expected 'client_credentials', " \
                      "but got '#{request_params['grant_type']}'")
        end

        assert messages.none? { |msg|
          msg[:type] == 'error'
        }, 'Invalid token requests detected. See messages for details.'
      end
    end
  end
end
