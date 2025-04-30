# frozen_string_literal: true

require 'smart_app_launch_test_kit'
require 'udap_security_test_kit'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    module PASClientOptions
      SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC =
        SMARTAppLaunch::SMARTClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
      UDAP_CLIENT_CREDENTIALS =
        UDAPSecurityTestKit::UDAPClientOptions::UDAP_CLIENT_CREDENTIALS
      DEDICATED_ENDPOINTS = DEDICATED_ENDPOINTS_AUTH_TAG
    end
  end
end
