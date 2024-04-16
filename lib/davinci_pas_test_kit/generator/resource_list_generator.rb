module DaVinciPASTestKit
  class Generator
    class ResourceListGenerator
      class << self
        def generate(ig_metadata, base_output_dir)
          @ig_metadata = ig_metadata

          FileUtils.mkdir_p(base_output_dir)
          File.write(File.join(base_output_dir, base_output_file_name), output)
        end

        def resource_list
          @ig_metadata.groups.map(&:title).uniq
        end

        def resource_supported_profiles
          dict = {}
          @ig_metadata.groups.each do |group|
            dict[group.resource] ||= []
            dict[group.resource] << group.profile_url
          end
          dict
        end

        def resource_list_string
          resource_list.map { |resource| "      '#{resource}'" }.join(",\n")
        end

        def module_name
          "PAS#{@ig_metadata.reformatted_version.upcase}"
        end

        def read_interaction(group_metadata)
          group_metadata.interactions.find { |interaction| interaction[:code] == 'read' } || {}
        end

        def submit_operation(group_metadata)
          group_metadata.operations.find { |operation| operation[:code] == '$submit' } || {}
        end

        def inquiry_operation(group_metadata)
          group_metadata.operations.find { |operation| operation[:code] == '$inquire' } || {}
        end

        def template
          @template ||= File.read(File.join(__dir__, 'templates', 'resource_list.rb.erb'))
        end

        def output
          ERB.new(template).result(binding)
        end

        def base_output_file_name
          'resource_list.rb'
        end
      end
    end
  end
end
