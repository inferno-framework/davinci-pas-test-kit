# frozen_string_literal: true

require_relative '../../urls'
require_relative '../../tags'
require_relative '../mock_udap_smart_server'

module DaVinciPASTestKit
  module MockUdapSmartServer
    class TokenEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        client_id_from_token_payload(MockUdapSmartServer.parsed_io_body(request))
      end

      def make_response
        parsed_body = MockUdapSmartServer.parsed_io_body(request)
        client_id = client_id_from_token_payload(parsed_body)

        exp_min = 60
        response_body = {
          access_token: MockUdapSmartServer.client_id_to_token(client_id, exp_min),
          token_type: 'Bearer',
          expires_in: 60 * exp_min
        }

        response.body = response_body.to_json
        response.headers['Cache-Control'] = 'no-store'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.content_type = 'application/json'
        response.status = 201
      end

      def update_result
        nil # never update for now
      end

      def tags
        [TOKEN_TAG]
      end

      private

      def client_id_from_token_payload(token_body)
        client_assertion_jwt = request_client_assertion_jwt(token_body)
        return unless client_assertion_jwt.present?

        MockUdapSmartServer.jwt_claims(client_assertion_jwt)&.dig('iss')
      end

      def request_client_assertion_jwt(token_body)
        token_body&.dig('client_assertion')
      end
    end
  end
end
