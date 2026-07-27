# frozen_string_literal: true

require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module MockUdapSmartServer
    class TokenEndpoint < Inferno::DSL::SuiteEndpoint
      include SMARTAppLaunch::MockSMARTServer::SMARTTokenResponseCreation
      include UDAPSecurityTestKit::MockUDAPServer::UDAPTokenResponseCreation

      def test_run_identifier
        UDAPSecurityTestKit::MockUDAPServer.client_id_from_client_assertion(request.params[:client_assertion])
      end

      def test_run_identifier_location_description
        "the client assertion's 'iss' claim representing the client's id"
      end

      def no_session_response
        response.status = 401
        response.format = :json
        response.body = {
          error: 'invalid_client',
          error_description: no_session_message

        }.to_json
      end

      def make_response
        if request.params[:udap].present?
          make_udap_client_credential_token_response
        else
          make_smart_client_credential_token_response
        end
      end

      def update_result
        nil # never update for now
      end

      def tags
        type_tag = request.params[:udap].present? ? UDAPSecurityTestKit::UDAP_TAG : SMARTAppLaunch::SMART_TAG
        [UDAPSecurityTestKit::TOKEN_TAG, UDAPSecurityTestKit::CLIENT_CREDENTIALS_TAG, type_tag]
      end
    end
  end
end
