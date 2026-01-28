require_relative '../cross_suite/pas_constants'

module DaVinciPASTestKit
  class Generator
    class UseCaseGroupGenerator
      class << self
        def generate(ig_metadata, base_server_output_dir)
          # Server Test Groups
          ['approval', 'denial', 'pended'].each do |use_case|
            new(ig_metadata, use_case, base_server_output_dir, 'server').generate
          end
        end
      end

      attr_accessor :ig_metadata, :use_case, :base_output_dir, :system

      def initialize(ig_metadata, use_case, base_output_dir, system = 'server')
        self.ig_metadata = ig_metadata
        self.use_case = use_case
        self.base_output_dir = base_output_dir
        self.system = system
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'use_case_group.rb.erb'))
      end

      def output
        @output ||= ERB.new(template, trim_mode: '-').result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def base_metadata_file_name
        'metadata.yml'
      end

      def class_name
        "PAS#{system.capitalize}#{use_case.camelize}UseCaseGroup"
      end

      def module_name
        "DaVinciPAS#{ig_metadata.reformatted_version.upcase}"
      end

      def title
        "Successful #{use_case.capitalize} Workflow"
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def profile_identifier(group_metadata)
        ig_metadata.snake_case_for_profile(group_metadata)
      end

      def group_id
        "pas_#{system}_#{ig_metadata.reformatted_version}_#{use_case}_use_case"
      end

      def ig_version
        ig_metadata.ig_version
      end

      def ig_version_for_id
        ig_metadata.reformatted_version
      end

      def generate
        FileUtils.mkdir_p(base_output_dir)
        File.write(output_file_name, output)
        ig_metadata.add_use_case_groups(group_id, base_output_file_name)
      end

      def operation_requirements_verified(operation)
        case "#{operation}_#{ig_version}"
        when 'submit_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@5', 'hl7.fhir.us.davinci-pas_2.0.1@66', 'hl7.fhir.us.davinci-pas_2.0.1@111',
           'hl7.fhir.us.davinci-pas_2.0.1@136', 'hl7.fhir.us.davinci-pas_2.0.1@207']
        when 'inquire_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@5', 'hl7.fhir.us.davinci-pas_2.0.1@111', 'hl7.fhir.us.davinci-pas_2.0.1@208']
        end
      end

      def notification_delivery_requirements_verified
        case ig_version
        when 'v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@141']
        end
      end

      def notification_conformance_requirements_verified
        case ig_version
        when 'v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@145']
        end
      end

      def bundle_response_conformance_requirements_verified(operation)
        case "#{operation}_#{ig_version}"
        when 'submit_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@64', 'hl7.fhir.us.davinci-pas_2.0.1@100',
           'hl7.fhir.us.davinci-pas_2.0.1@101', 'hl7.fhir.us.davinci-pas_2.0.1@102',
           'hl7.fhir.us.davinci-pas_2.0.1@103', 'hl7.fhir.us.davinci-pas_2.0.1@107']
        when 'inquire_v2.0.1'
          ['hl7.fhir.us.davinci-pas_2.0.1@131']
        end
      end

      def description
        case system
        when 'server'
          case use_case # rubocop:disable Style/HashLikeCase
          when 'approval'
            <<~DESCRIPTION
              Demonstrate the ability of the server to respond to a prior
              authorization request with an `approved` decision.
            DESCRIPTION
          when 'denial'
            <<~DESCRIPTION
              Demonstrate the ability of the server to respond to a prior
              authorization request with a `denied` decision.
            DESCRIPTION
          when 'pended'
            <<~DESCRIPTION
              Demonstrate a complete prior authorization workflow including a period
              during which the final decision is pending. This includes demonstrating
              the ability of the server to

              - Respond to a prior authorization request with a `pended` status.
              - Accept a Subscription creation request and send a notification when
                the pended claim has been finalized.
              - Respond to a subsequent inquiry request with a final decision for the request.
            DESCRIPTION
          end
        end
      end

      def bundle_validation_test_title(operation, type)
        if type == 'request'
          "[USER INPUT VALIDATION] Provided $#{operation} Request Bundle is conformant"
        else
          "Server $#{operation} Response Bundle is conformant"
        end
      end

      def profile_link(operation, type)
        "[#{PASConstants.bundle_profile_name_for_operation_and_type(operation, type)}]" \
          "(#{PASConstants.bundle_profile_url_for_operation_and_type(operation, type)}|#{ig_version})"
      end

      def bundle_validation_test_description(operation, type)
        <<~DESCRIPTION
          #{"#{description_user_input_validation}\n" if type == 'request'}This test validates the conformity of the
          #{type == 'request' ? 'user input' : "server's response"} to the
          #{profile_link(operation, type)}
          profile#{type == 'request' ? ', ensuring subsequent tests can accurately simulate content.' : '.'}

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
