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

      def recursive_remove_input(runnable, input)
        runnable.inputs.delete(input)
        runnable.input_order.delete(input)
        runnable.children.each { |child_runnable| recursive_remove_input(child_runnable, input) }
      end
    end
  end
end
