require 'pry'
require_relative 'naming'

module DaVinciPASTestKit
  class Generator
    class ValidationTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir)
          ig_metadata.bundle_groups.each do |group|
            new(group, base_output_dir:).generate
          end
        end
      end

      attr_accessor :group_metadata, :medication_request_metadata, :base_output_dir, :workflow

      def initialize(group_metadata, workflow = nil, medication_request_metadata = nil, base_output_dir:)
        self.group_metadata = group_metadata
        self.workflow = workflow
        self.medication_request_metadata = medication_request_metadata
        self.base_output_dir = base_output_dir
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'validation.rb.erb'))
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

      def formatted_workflow
        workflow.to_s.split('_').first.to_s
      end

      def test_id
        pref = "pas_server_#{group_metadata.reformatted_version}_#{formatted_workflow}".delete_suffix('_')
        "#{pref}_#{profile_identifier}_validation_test"
      end

      def class_name
        pref = "Server#{formatted_workflow.camelize}"
        "#{pref}#{Naming.upper_camel_case_for_profile(group_metadata)}ValidationTest"
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
        pref = user_input? ? '[USER INPUT VALIDATION] ' : ''
        "#{pref}#{group_metadata.title} is valid"
      end

      def user_input?
        request_type.include?('request')
      end

      def description
        <<~DESCRIPTION
          #{description_user_input_validation if user_input?}

          This test validates the conformity of the
          #{request_type.include?('request') ? 'user input' : "server's response"} to the
          [#{profile_name}](#{profile_url})#{' '}
          structure#{request_type.include?('request') ? ', ensuring subsequent tests can accurately simulate content.' : '.'}

          It also checks that other conformance requirements defined in the [PAS Formal
          Specification](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html),
          such as the presence of all referenced instances within the bundle and the
          conformance of those instances to the appropriate profiles, are met.

          It verifies the presence of mandatory elements and that elements with
          required bindings contain appropriate values. CodeableConcept element
          bindings will fail if none of their codings have a code/system belonging
          to the bound ValueSet. Quantity, Coding, and code element bindings will
          fail if their code/system are not found in the valueset.

          Note that because X12 value sets are not public, elements bound to value
          sets containing X12 codes are not validated.

          **Limitations**

          Due to recognized errors in the PAS IG around extension context definitions,
          this test may not pass due to spurious errors of the form "The extension
          [extension url] is not allowed at this point". See [this
          issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues/11)
          for additional details.
        DESCRIPTION
      end

      def description_user_input_validation
        <<~USER_INPUT_INTRO
          **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
          Errors encountered will be treated as a skip instead of a failure.
        USER_INPUT_INTRO
      end
    end
  end
end
