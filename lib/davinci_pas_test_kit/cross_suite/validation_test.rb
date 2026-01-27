# frozen_string_literal: true

module DaVinciPASTestKit
  module ValidationTest
    def perform_validation_test(resources,
                                profile_url,
                                profile_version,
                                skip_if_empty: true)
      skip_if skip_if_empty && resources.blank?,
              "No #{resource_type} resources conforming to the #{profile_url} profile were returned"

      omit_if resources.blank?,
              "No #{resource_type} resources provided so the #{profile_url} profile does not apply"

      profile_with_version = "#{profile_url}|#{profile_version}"
      resources.each do |resource|
        resource_is_valid?(resource:, profile_url: profile_with_version)
      end

      errors_found = messages.any? { |message| message[:type] == 'error' }

      assert !errors_found, "Resource does not conform to the profile #{profile_with_version}"
    end
  end
end
