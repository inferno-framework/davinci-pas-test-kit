require_relative 'naming'

module DaVinciPASTestKit
  class Generator
    class SuiteGenerator
      class << self
        def generate(ig_metadata, base_output_dir)
          new(ig_metadata, base_output_dir).generate
        end
      end

      attr_accessor :ig_metadata, :base_output_dir

      def initialize(ig_metadata, base_output_dir)
        self.ig_metadata = ig_metadata
        self.base_output_dir = base_output_dir
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'suite.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        'server_suite.rb'
      end

      def class_name
        'ServerSuite'
      end

      def module_name
        "DaVinciPAS#{ig_metadata.reformatted_version.upcase}"
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def suite_id
        "davinci_pas_server_suite_#{ig_metadata.reformatted_version}"
      end

      def title
        "Da Vinci PAS Server Suite #{ig_metadata.ig_version}"
      end

      def ig_link
        case ig_metadata.ig_version
        when 'v2.0.1'
          'https://hl7.org/fhir/us/davinci-pas/STU2/'
        else
          'https://hl7.org/fhir/us/davinci-pas/history.html'
        end
      end

      def generate
        File.write(output_file_name, output)
      end

      def groups
        ig_metadata.use_case_groups
      end

      def group_id_list
        @group_id_list ||= groups.map { |group| group[:id] }
          .reject { |id| id.include?('client') }
          .reject { |id| id.include?('must_support') }
      end

      def group_file_list
        @group_file_list ||= groups.map { |group| group[:file_name].delete_suffix('.rb') }
          .reject { |name| name.include?('client') }
      end

      def error_group_file_name
        "../../custom_groups/#{ig_metadata.ig_version}/pas_error_group"
      end

      def error_group_id
        "pas_#{ig_metadata.reformatted_version}_error_group"
      end

      def must_support_group_id
        @must_support_group_id ||= groups.map { |group| group[:id] }
          .reject { |id| id.include?('client') }
          .find { |id| id.include?('must_support') }
      end
    end
  end
end
