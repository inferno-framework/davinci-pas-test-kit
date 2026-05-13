# frozen_string_literal: true

module DaVinciPASTestKit
  RESUME_PASS_PATH = '/resume_pass'
  RESUME_FAIL_PATH = '/resume_fail'
  RESUME_SKIP_PATH = '/resume_skip'

  # base url, plus other shared ones such as resume urls
  # suite_id must be defined
  module BaseURLs
    def base_url
      @base_url ||= "#{Inferno::Application['base_url']}/custom/#{suite_id}"
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
  end
end
