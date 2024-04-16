require 'pry'
require_relative '../generated/v2.0.1/resource_list'

module DaVinciPASTestKit
  class Generator
    module Naming
      class << self
        include DaVinciPASTestKit::PASV201::ResourceList
        def resources_with_multiple_profiles
          resources = []
          RESOURCE_SUPPORTED_PROFILES.each do |resource, profile_list|
            resources << resource.to_s if profile_list.length > 1
          end
          resources
        end

        def resource_has_multiple_profiles?(resource)
          resources_with_multiple_profiles.include? resource
        end

        def request_type_for_bundle_or_claim
          {
            'PAS Request Bundle' => 'submit_request',
            'PAS Response Bundle' => 'submit_response',
            'PAS Inquiry Request Bundle' => 'inquire_request',
            'PAS Inquiry Response Bundle' => 'inquire_response',
            'PAS Claim' => 'submit_request',
            'PAS Claim Response' => 'submit_response',
            'PAS Claim Inquiry' => 'inquire_request',
            'PAS Claim Inquiry Response' => 'inquire_response',
            'PAS Claim Update' => 'update_request'
          }
        end

        def snake_case_for_profile(group_metadata)
          resource = group_metadata.resource
          return resource.underscore unless resource_has_multiple_profiles?(resource)

          group_metadata.name
            .delete_prefix('profile_')
            .underscore
        end

        def upper_camel_case_for_profile(group_metadata)
          snake_case_for_profile(group_metadata).camelize
        end
      end
    end
  end
end
