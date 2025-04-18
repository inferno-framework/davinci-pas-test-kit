# frozen_string_literal: true

require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'

module DaVinciPASTestKit
  SESSION_PATH_PLACEHOLDER = '/:session_path'
  FHIR_PATH = '/fhir'
  SESSION_FHIR_PATH = SESSION_PATH_PLACEHOLDER + FHIR_PATH
  SUBMIT_PATH = "#{FHIR_PATH}/Claim/$submit".freeze
  SESSION_SUBMIT_PATH = SESSION_PATH_PLACEHOLDER + SUBMIT_PATH
  INQUIRE_PATH = "#{FHIR_PATH}/Claim/$inquire".freeze
  SESSION_INQUIRE_PATH = SESSION_PATH_PLACEHOLDER + INQUIRE_PATH
  FHIR_SUBSCRIPTION_PATH = "#{FHIR_PATH}/Subscription".freeze
  SESSION_FHIR_SUBSCRIPTION_PATH =  SESSION_PATH_PLACEHOLDER + FHIR_SUBSCRIPTION_PATH
  FHIR_SUBSCRIPTION_INSTANCE_PATH = "#{FHIR_SUBSCRIPTION_PATH}/:id".freeze
  SESSION_FHIR_SUBSCRIPTION_INSTANCE_PATH = SESSION_PATH_PLACEHOLDER + FHIR_SUBSCRIPTION_INSTANCE_PATH
  FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH = "#{FHIR_SUBSCRIPTION_INSTANCE_PATH}/$status".freeze
  SESSION_FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH = SESSION_PATH_PLACEHOLDER + FHIR_SUBSCRIPTION_INSTANCE_STATUS_PATH
  FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH = "#{FHIR_SUBSCRIPTION_PATH}/$status".freeze
  SESSION_FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH = SESSION_PATH_PLACEHOLDER + FHIR_SUBSCRIPTION_RESOURCE_STATUS_PATH
  RESUME_PASS_PATH = '/resume_pass'
  RESUME_FAIL_PATH = '/resume_fail'
  RESUME_SKIP_PATH = '/resume_skip'

  module URLs
    def base_url
      @base_url ||= "#{Inferno::Application['base_url']}/custom/#{suite_id}"
    end

    def fhir_base_url
      @fhir_base_url ||= base_url + FHIR_PATH
    end

    def session_fhir_base_url(session_path)
      return fhir_base_url if session_path.blank?

      base_url + SESSION_FHIR_PATH.gsub(SESSION_PATH_PLACEHOLDER, "/#{session_path}")
    end

    def submit_url
      @submit_url ||= base_url + SUBMIT_PATH
    end

    def session_submit_url(session_path)
      return submit_url if session_path.blank?

      base_url + SESSION_SUBMIT_PATH.gsub(SESSION_PATH_PLACEHOLDER, "/#{session_path}")
    end

    def inquire_url
      @inquire_url ||= base_url + INQUIRE_PATH
    end

    def session_inquire_url(session_path)
      return inquire_url if session_path.blank?

      base_url + SESSION_INQUIRE_PATH.gsub(SESSION_PATH_PLACEHOLDER, "/#{session_path}")
    end

    def fhir_subscription_url
      @fhir_subscription_url ||= base_url + FHIR_SUBSCRIPTION_PATH
    end

    def session_fhir_subscription_url(session_path)
      return fhir_subscription_url if session_path.blank?

      base_url + SESSION_FHIR_SUBSCRIPTION_PATH.gsub(SESSION_PATH_PLACEHOLDER, "/#{session_path}")
    end

    def resume_pass_url
      @resume_pass_url ||= base_url + RESUME_PASS_PATH
    end

    def resume_fail_url
      @resume_fail_url ||= base_url + RESUME_FAIL_PATH
    end

    def resume_skip_url
      @resume_skip_url ||= base_url + RESUME_SKIP_PATH
    end

    def udap_discovery_url
      @udap_discovery_url ||= base_url + UDAPSecurityTestKit::UDAP_DISCOVERY_PATH
    end

    def token_url
      @token_url ||= base_url + UDAPSecurityTestKit::TOKEN_PATH
    end

    def registration_url
      @registration_url ||= base_url + UDAPSecurityTestKit::REGISTRATION_PATH
    end

    def suite_id
      self.class.suite.id
    end
  end
end
