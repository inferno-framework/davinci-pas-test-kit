module DaVinciPASTestKit
  class Generator
    class IGResources
      def add(resource)
        resources_by_type[resource.resourceType] << resource
      end

      def capability_statement(mode = 'server')
        resources_by_type['CapabilityStatement'].find do |capability_statement_resource|
          capability_statement_resource.rest.any? { |r| r.mode == mode }
        end
      end

      def base_resources_and_supported_profiles
        definitions = [
          'ImplementationGuide',
          'CapabilityStatement',
          'CodeSystem',
          'OperationDefinition',
          'StructureDefinition',
          'ValueSet'
        ]
        base_resources = resources_by_type.keys.reject { |k| definitions.include?(k) }
        resource_profiles = {}
        base_resources.each do |res|
          profile_urls = resources_by_type['StructureDefinition'].find_all { |p| p.type == res }.map(&:url)
          resource_profiles[res] = profile_urls
        end
        resource_profiles
      end

      def ig
        resources_by_type['ImplementationGuide'].first
      end

      def inspect
        'IGResources'
      end

      def profile_by_url(url)
        resources_by_type['StructureDefinition'].find { |profile| profile.url == url }
      end

      def resource_type_for_profile(url)
        profile_by_url(url).type
      end

      def value_set_by_url(url)
        resources_by_type['ValueSet'].find { |profile| profile.url == url }
      end

      def code_system_by_url(url)
        resources_by_type['CodeSystem'].find { |profile| profile.url == url }
      end

      # def search_param_by_resource_and_name(resource, name)
      #   # remove '_' from search parameter name, such as _id or _tag
      #   normalized_name = normalized_name = name.to_s.delete_prefix('_')

      #   param = resources_by_type['SearchParameter']
      #     .find { |param| param.id == "#{resource.downcase}-#{normalized_name}" }

      #   if param.nil?
      #     param = resources_by_type['SearchParameter']
      #       .find { |param| param.id == "Resource-#{normalized_name}" }
      #   end

      #   return param
      # end

      private

      def resources_by_type
        @resources_by_type ||= Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end
end
