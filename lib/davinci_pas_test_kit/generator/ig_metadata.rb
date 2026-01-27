module DaVinciPASTestKit
  class Generator
    class IGMetadata
      attr_accessor :ig_version, :groups, :use_case_groups

      def reformatted_version
        @reformatted_version ||= ig_version.delete('.-')
      end

      def add_use_case_groups(id, file_name)
        @use_case_groups ||= []
        @use_case_groups << { id:, file_name: }
      end

      def bundle_groups
        @bundle_groups ||=
          groups.select { |group| group.resource == 'Bundle' }
            .reject { |group| group.profile_name.include?('Base') }
      end

      def claim_groups
        @claim_groups ||=
          groups.select { |group| group.resource == 'Claim' }
            .reject { |group| group.profile_name.include?('Base') }
      end

      def to_hash
        {
          ig_version:,
          groups: groups.map(&:to_hash)
        }
      end

      def resources_with_multiple_profiles
        @resources_with_multiple_profiles ||= fetch_resources_with_multiple_profiles
      end

      def fetch_resources_with_multiple_profiles
        metadata = YAML.load_file(File.join(__dir__, '..', 'cross_suite', 'generated', 'v2.0.1', 'metadata.yml'),
                                  aliases: true)
        resource_supported_profiles = metadata[:groups].each_with_object({}) do |group, dict|
          dict[group[:resource]] ||= []
          dict[group[:resource]] << group[:profile_url]
        end

        resources = []
        resource_supported_profiles.each do |resource, profile_list|
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
