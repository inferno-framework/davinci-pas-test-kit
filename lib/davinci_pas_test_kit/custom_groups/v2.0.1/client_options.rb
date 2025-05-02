# frozen_string_literal: true

require 'smart_app_launch_test_kit'
require 'udap_security_test_kit'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    module PASClientOptions
      module_function

      SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC =
        SMARTAppLaunch::SMARTClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
      UDAP_CLIENT_CREDENTIALS =
        UDAPSecurityTestKit::UDAPClientOptions::UDAP_CLIENT_CREDENTIALS
      DEDICATED_ENDPOINTS = DEDICATED_ENDPOINTS_AUTH_TAG

      UNUSED_INPUT_LIST = {
        SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC => [:session_url_path],
        UDAP_CLIENT_CREDENTIALS => [:session_url_path],
        DEDICATED_ENDPOINTS => [:client_id]
      }.freeze

      def clean_unused_inputs(runnable, client_type)
        UNUSED_INPUT_LIST[client_type].each { |input| recursive_remove_input(runnable, input) }
      end

      def recursive_remove_input(runnable, input)
        runnable.inputs.delete(input)
        runnable.children.each { |child_runnable| recursive_remove_input(child_runnable, input) }
      end

      def unused_input_list
        if suite_options[:client_type] == SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
          AUTHORIZATION_CODE_TAG
        elsif suite_options[:client_type].include?(CLIENT_CREDENTIALS_TAG)
          CLIENT_CREDENTIALS_TAG
        end
      end
    end
  end
end
