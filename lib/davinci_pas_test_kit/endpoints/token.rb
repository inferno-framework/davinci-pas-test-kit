# frozen_string_literal: true

require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../urls'
require_relative '../tags'

module DaVinciPASTestKit
  module MockUdapSmartServer
    class TokenEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        UDAPSecurityTestKit::MockUDAPServer.client_id_from_client_assertion(request.params[:client_assertion])
      end

      def make_response
        if request.params[:udap].present?
          UDAPSecurityTestKit::MockUDAPServer.make_udap_token_response(request, response, test_run.test_session_id)
        else
          SMARTAppLaunch::MockSMARTServer.make_smart_token_response(request, response, result)
        end
      end

      def update_result
        nil # never update for now
      end

      def tags
        type_tag = request.params[:udap].present? ? UDAPSecurityTestKit::UDAP_TAG : SMARTAppLaunch::SMART_TAG
        [UDAPSecurityTestKit::TOKEN_TAG, type_tag]
      end
    end
  end
end
