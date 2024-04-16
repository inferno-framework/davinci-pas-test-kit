# frozen_string_literal: true

module DaVinciPASTestKit
  TOKEN_PATH = '/mock_auth/token'
  SUBMIT_PATH = '/fhir/Claim/$submit'
  INQUIRE_PATH = '/fhir/Claim/$inquire'
  RESUME_PASS_PATH = '/resume_pass'
  RESUME_FAIL_PATH = '/resume_fail'

  module URLs
    def base_url
      @base_url ||= "#{Inferno::Application['base_url']}/custom/#{suite_id}"
    end

    def token_url
      @token_url ||= base_url + TOKEN_PATH
    end

    def submit_url
      @submit_url ||= base_url + SUBMIT_PATH
    end

    def inquire_url
      @inquire_url ||= base_url + INQUIRE_PATH
    end

    def resume_pass_url
      @resume_pass_url ||= base_url + RESUME_PASS_PATH
    end

    def resume_fail_url
      @resume_fail_url ||= base_url + RESUME_FAIL_PATH
    end

    def suite_id
      self.class.suite.id
    end
  end
end
