require 'pry'
require_relative 'naming'

module DaVinciPASTestKit
  class Generator
    class OperationTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir)
          ig_metadata.claim_groups
            .reject { |group| group.name.include?('update') }
            .each do |group|
              new(group, base_output_dir:).generate
            end
        end
      end

      attr_accessor :group_metadata, :medication_request_metadata, :base_output_dir

      def initialize(group_metadata, medication_request_metadata = nil, base_output_dir:)
        self.group_metadata = group_metadata
        self.medication_request_metadata = medication_request_metadata
        self.base_output_dir = base_output_dir
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'operation.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def output_file_directory
        File.join(base_output_dir, directory_name)
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def directory_name
        Naming.snake_case_for_profile(medication_request_metadata || group_metadata)
      end

      def profile_identifier
        Naming.snake_case_for_profile(group_metadata)
      end

      def profile_url
        group_metadata.profile_url
      end

      def profile_name
        group_metadata.profile_name
      end

      def profile_version
        group_metadata.profile_version
      end

      def test_id
        "pas_#{group_metadata.reformatted_version}_#{profile_identifier}_operation_test"
      end

      def class_name
        "#{Naming.upper_camel_case_for_profile(group_metadata)}OperationTest"
      end

      def module_name
        "DaVinciPAS#{group_metadata.reformatted_version.upcase}"
      end

      def resource_type
        group_metadata.resource
      end

      def conformance_expectation
        read_interaction[:expectation]
      end

      def skip_if_empty
        # Return true if a system must demonstrate at least one example of the resource type.
        # This drives omit vs. skip result statuses in this test.
        resource_type != 'Medication'
      end

      def request_type
        Naming.request_type_for_bundle_or_claim[profile_name]
      end

      def operation
        operations = group_metadata.operations.map { |op| op[:code] }
        operations.find { |op| request_type.include?(op.delete_prefix('$')) }
          .to_s.delete_prefix('$')
      end

      def operation_name
        case operation
        when 'inquire'
          'Inquiry'
        when 'submit'
          'Submit'
        end
      end

      def generate
        FileUtils.mkdir_p(output_file_directory)
        File.write(output_file_name, output)

        test_metadata = {
          id: test_id,
          file_name: base_output_file_name
        }
        group_metadata.add_test(**test_metadata)
      end

      def title
        "Submission of a claim to the $#{operation} operation succeeds"
      end

      def description
        <<~DESCRIPTION
          Server SHALL support PAS #{operation_name} requests: a POST interaction to
          the /Claim/$#{operation} endpoint.
          This test submits a Prior Authorization #{operation_name} request to the server and verifies that a
          response is returned with HTTP status 2XX.
          #{operation == 'submit' ? 'The server SHOULD respond within 15 seconds.' : ''}
        DESCRIPTION
      end
    end
  end
end
