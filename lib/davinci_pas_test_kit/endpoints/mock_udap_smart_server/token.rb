# frozen_string_literal: true

require_relative '../../urls'
require_relative '../../tags'
require_relative '../mock_udap_smart_server'

module DaVinciPASTestKit
  module MockUdapSmartServer
    class TokenEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        client_id_from_client_assertion(request.params[:client_assertion])
      end

      def make_response
        client_id = client_id_from_client_assertion(request.params[:client_assertion])

        exp_min = 60
        response_body = {
          access_token: MockUdapSmartServer.client_id_to_token(client_id, exp_min),
          token_type: 'Bearer',
          expires_in: 60 * exp_min
        }
        if !request.params['udap'].present? && request.params['scopes'].present?
          response_body['scopes'] = request.params['scopes']
        end

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
        type_tag = request.params['udap'].present? ? UDAP_TAG : SMART_TAG
        [TOKEN_TAG, type_tag]
      end

      private

      def client_id_from_client_assertion(client_assertion_jwt)
        return unless client_assertion_jwt.present?

        MockUdapSmartServer.jwt_claims(client_assertion_jwt)&.dig('iss')
      end
    end
  end
end
