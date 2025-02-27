require_relative 'naming'

module DaVinciPASTestKit
  class Generator
    class GroupGenerator
      class << self
        def generate(ig_metadata, base_output_dir)
          groups = ig_metadata.groups.select { |group| group.tests.present? }.reject do |group|
            group.profile_name.include?('Base')
          end
          # Server Test Groups
          ['approval', 'denial', 'pended', 'must_support'].each_with_index do |use_case, index|
            new(ig_metadata, use_case, groups, base_output_dir, 'server', index.zero?).generate
          end

          # Client Test Groups
          ['submit_must_support', 'inquiry_must_support'].each do |use_case|
            new(ig_metadata, use_case, groups, base_output_dir, 'client', false).generate
          end
        end
      end

      attr_accessor :ig_metadata, :use_case, :groups, :base_output_dir, :first_generate, :system

      def initialize(ig_metadata, use_case, groups, base_output_dir, system = 'server', first_generate = false)
        self.ig_metadata = ig_metadata
        self.use_case = use_case
        self.groups = groups
        self.base_output_dir = base_output_dir
        self.system = system
        self.first_generate = first_generate
      end

      def template
        @template ||= File.read(File.join(__dir__, 'templates', 'group.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
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
        "DaVinciPAS#{groups.first.reformatted_version.upcase}"
      end

      def title
        if use_case.include?('must_support')
          return 'Submit Request Must Support' if system == 'client' && use_case.include?('submit')
          return 'Inquiry Request Must Support' if system == 'client'

          'Demonstrate Element Support'
        else
          "Successful #{use_case.capitalize} Workflow"
        end
      end

      def run_as_group
        return false if use_case.include?('must_support') && system == 'server'

        true
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def metadata_file_name(group)
        File.join(base_output_dir, profile_identifier(group), base_metadata_file_name)
      end

      def profile_identifier(group_metadata)
        Naming.snake_case_for_profile(group_metadata)
      end

      def group_id
        "pas_#{system}_#{groups.first.reformatted_version}_#{use_case}_use_case"
      end

      def generate
        File.write(output_file_name, output)
        ig_metadata.add_use_case_groups(group_id, base_output_file_name)
        return unless first_generate

        groups.each do |group_metadata|
          File.write(metadata_file_name(group_metadata), YAML.dump(group_metadata.to_hash))
        end
      end

      def all_tests
        @all_tests ||= groups.flat_map(&:tests).compact
      end

      def all_test_ids
        @all_test_ids = all_tests.map { |test| test[:id] }.reject do |id|
          id.include?('medication_request_must_support') || id.include?('service_request_must_support') ||
            id.include?('device_request_must_support') || id.include?('nutrition_order_must_support')
        end
      end

      def select_test_ids(include_patterns, exclude_patterns = [])
        all_test_ids.select do |id|
          include_conditions = include_patterns.all? { |pattern| id.include?(pattern) }
          exclude_conditions = exclude_patterns.none? { |pattern| id.include?(pattern) }
          include_conditions && exclude_conditions
        end
      end

      def submit_request_validation_test_ids
        @submit_request_validation_test_ids ||= select_test_ids(['request', 'validation_test'], ['inquiry', 'client'])
      end

      def inquiry_request_validation_test_ids
        @inquiry_request_validation_test_ids ||= select_test_ids(['request', 'validation_test', 'inquiry'], ['client'])
      end

      def submit_response_validation_test_ids
        @submit_response_validation_test_ids ||= select_test_ids(['response', 'validation_test'], ['inquiry', 'client'])
      end

      def inquiry_response_validation_test_ids
        @inquiry_response_validation_test_ids ||= select_test_ids(['response', 'validation_test', 'inquiry'],
                                                                  ['client'])
      end

      def submit_request_must_support_test_ids
        @submit_request_must_support_test_ids ||= select_test_ids(['submit_request', 'must_support_test'], ['client'])
          .unshift(pas_submit_must_support_requirement_test_id)
      end

      def client_submit_request_must_support_test_ids
        @client_submit_request_must_support_test_ids ||= select_test_ids(
          ['submit_request', 'must_support_test'],
          ['server']
        ).unshift(pas_client_must_support_test_id, pas_submit_must_support_requirement_test_id)
      end

      def inquiry_request_must_support_test_ids
        @inquiry_request_must_support_test_ids ||= select_test_ids(['inquire_request', 'must_support_test'], ['client'])
      end

      def client_inquiry_request_must_support_test_ids
        @client_inquiry_request_must_support_test_ids ||= select_test_ids(
          ['inquire_request', 'must_support_test'],
          ['server']
        ).unshift(pas_client_must_support_test_id)
      end

      def submit_response_must_support_test_ids
        @submit_response_must_support_test_ids ||= select_test_ids(['submit_response', 'must_support_test'])
      end

      def inquiry_response_must_support_test_ids
        @inquiry_response_must_support_test_ids ||= select_test_ids(['inquire_response', 'must_support_test'])
      end

      def submit_operation_test_ids
        @submit_operation_test_ids ||= select_test_ids(['operation_test'], ['inquiry'])
      end

      def inquiry_operation_test_ids
        @inquiry_operation_test_ids ||= select_test_ids(['operation_test', 'inquiry'])
      end

      def approval_denial_test_ids
        submit_request_validation_test_ids + submit_operation_test_ids +
          submit_response_validation_test_ids + [claim_response_decision_test_id]
      end

      def grouped_approval_denial_test_ids
        {
          'Server can respond to claims submitted for prior authorization' =>
            approval_denial_test_ids
        }
      end

      def pended_test_ids
        approval_denial_test_ids + inquiry_request_validation_test_ids +
          inquiry_operation_test_ids + inquiry_response_validation_test_ids
      end

      def grouped_pended_test_ids
        inquiry_operation = [inquiry_notification_test_id] +
                            inquiry_request_validation_test_ids +
                            inquiry_operation_test_ids +
                            inquiry_response_validation_test_ids
        inquiry_tests = {
          'Server can respond to claims submitted for inquiry' => inquiry_operation
        }

        grouped_approval_denial_test_ids.merge(inquiry_tests)
      end

      def must_support_test_ids
        pended_test_ids + submit_request_must_support_test_ids + submit_response_must_support_test_ids +
          inquiry_request_must_support_test_ids + inquiry_response_must_support_test_ids
      end

      def grouped_must_support_test_ids
        submit_tests = submit_request_validation_test_ids +
                       submit_operation_test_ids +
                       submit_response_validation_test_ids
        inquiry_operation = inquiry_request_validation_test_ids +
                            inquiry_operation_test_ids +
                            inquiry_response_validation_test_ids
        {
          '$submit Element Support' => {
            'Submission of claims to the $submit operation for must support validation' => submit_tests,
            '[USER INPUT VALIDATION] Submit Request Must Support' => submit_request_must_support_test_ids,
            'Submit Response Must Support' => submit_response_must_support_test_ids
          },
          '$inquire Element Support' => {
            'Submission of claims to the $inquire operation for must support validation' => inquiry_operation,
            '[USER INPUT VALIDATION] Inquiry Request Must Support' => inquiry_request_must_support_test_ids,
            'Inquiry Response Must Support' => inquiry_response_must_support_test_ids
          }
        }
      end

      def common_test_file_list(test_ids)
        test_ids.map do |id|
          test = all_tests.find { |t| t[:id] == id }
          next unless test

          group = groups.find { |grp| grp.tests.include?(test) }
          name_without_suffix = test[:file_name].delete_suffix('.rb')
          test_file = if name_without_suffix.start_with?('..')
                        name_without_suffix
                      else
                        "#{profile_identifier(group)}/#{name_without_suffix}"
                      end
          test_file
        end.compact
      end

      def approval_denial_test_file_list
        common_test_file_list(approval_denial_test_ids) << claim_response_decision_file_name
      end

      def pended_test_file_list
        common_test_file_list(pended_test_ids).push(
          claim_response_decision_file_name,
          subscription_notification_file_name
        )
      end

      def must_support_test_file_list
        common_test_file_list(must_support_test_ids).push(pas_submit_must_support_requirement_test_file)
      end

      def client_submit_request_must_support_test_file_list
        common_test_file_list(client_submit_request_must_support_test_ids)
          .push(pas_submit_must_support_requirement_test_file, pas_client_must_support_test_file)
      end

      def client_inquiry_request_must_support_test_file_list
        common_test_file_list(client_inquiry_request_must_support_test_ids)
          .push(pas_client_must_support_test_file)
      end

      def test_id_list
        @test_id_list ||= if system == 'client'
                            if use_case == 'submit_must_support'
                              client_submit_request_must_support_test_ids
                            else
                              client_inquiry_request_must_support_test_ids
                            end
                          elsif ['approval', 'denial'].include?(use_case)
                            grouped_approval_denial_test_ids
                          elsif use_case == 'pended'
                            grouped_pended_test_ids
                          else
                            grouped_must_support_test_ids
                          end
      end

      def test_file_list
        @test_file_list ||= if system == 'client'
                              if use_case == 'submit_must_support'
                                client_submit_request_must_support_test_file_list
                              else
                                client_inquiry_request_must_support_test_file_list
                              end
                            elsif ['approval', 'denial'].include?(use_case)
                              approval_denial_test_file_list
                            elsif use_case == 'pended'
                              pended_test_file_list
                            else
                              must_support_test_file_list
                            end
      end

      def claim_response_decision_test_id
        'prior_auth_claim_response_decision_validation'
      end

      def inquiry_notification_test_id
        'prior_auth_claim_response_update_notification_validation'
      end

      def claim_response_decision_file_name
        "../../custom_groups/#{ig_metadata.ig_version}/claim_response_decision/pas_claim_response_decision_test"
      end

      def subscription_notification_file_name
        "../../custom_groups/#{ig_metadata.ig_version}/notification/pas_subscription_notification_test"
      end

      def rename_input?(test_id)
        (test_id.include?('request') && test_id.include?('validation') && !test_id.include?('inquiry')) ||
          test_id.include?('operation_test')
      end

      def must_support_rename_input?(test_id)
        (test_id.include?('request') && test_id.include?('validation')) ||
          test_id.include?('operation_test')
      end

      def alt_test_id(id, use_case)
        "#{id}_#{use_case}"
      end

      def alt_request_input_name(use_case, request_type)
        "#{use_case}_pa_#{request_type}_request_payload"
      end

      def alt_request_input_title(use_case, request_type)
        if use_case == 'must_support'
          "Additional PAS #{request_type.capitalize} Request Payloads"
        else
          "PAS #{request_type.capitalize} Request Payload for #{use_case.capitalize} Response"
        end
      end

      def pas_submit_must_support_requirement_test_id
        "pas_#{system}_submit_#{ig_metadata.reformatted_version}_must_support_requirement"
      end

      def pas_submit_must_support_requirement_test_file
        "../../custom_groups/#{ig_metadata.ig_version}/must_support/pas_#{system}_must_support_requirement_test"
      end

      # Client tests initiation for must support: tests to allow the client to send $submit/$inquire requests in
      # addition to any already sent in previous test groups for Inferno to evaluate coverage of must support elements.
      def pas_client_must_support_test_id
        request_type = use_case.include?('submit') ? 'submit' : 'inquire'
        "pas_client_#{request_type}_#{ig_metadata.reformatted_version}_must_support_test"
      end

      def pas_client_must_support_test_file
        request_type = use_case.include?('submit') ? 'submit' : 'inquire'
        "../../custom_groups/#{ig_metadata.ig_version}/client_tests/pas_client_#{request_type}_must_support_test"
      end

      def description
        case system
        when 'server'
          case use_case
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
          else # must_support
            <<~DESCRIPTION
              Demonstrate the ability of the server to support all PAS-defined profiles
              and the must support elements defined in them. This includes

              - the ability to respond to prior authorization submission and inquiry
                requests that contain all PAS-defined profiles and their must support
                elements.
              - the ability to include in those responses all PAS-defined profiles
                and their must support elements.

              In order to allow Inferno to observe and validate these criteria, testers
              are required to provide a set of `$submit` and `$inquire` requests that
              collectively both themselves contain and elicit server responses that contain
              all PAS-defined profiles and their must support elements.
            DESCRIPTION
          end
        when 'client'
          if use_case.include?('submit')
            <<~DESCRIPTION
              Check that the client can demonstrate `$submit` requests that contain
              all PAS-defined profiles and their must support elements.

              For `$submit` requests, this includes the following profiles:

              - [PAS Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-request-bundle.html)
              - [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-update.html)
              - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-coverage.html)
              - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
              - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
              - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
              - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
              - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
              - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
              - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-encounter.html)
              - At least one of the following request profiles
                - [PAS Device Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-devicerequest.html)
                - [PAS Medication Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-medicationrequest.html)
                - [PAS Nutrition Order](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-nutritionorder.html)
                - [PAS Service Request](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-servicerequest.html)
            DESCRIPTION
          else # inquire
            <<~DESCRIPTION
              Check that the client can demonstrate `$inquire` requests that contain
              all PAS-defined profiles and their must support elements.

              For `$inquire` requests, this includes the following profiles:

              - [PAS Inquiry Request Bundle](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-pas-inquiry-request-bundle.html)
              - [PAS Claim Inquiry](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-claim-inquiry.html)
              - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-coverage.html)
              - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-beneficiary.html)
              - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-subscriber.html)
              - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-insurer.html)
              - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-requestor.html)
              - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitioner.html)
              - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-practitionerrole.html)
            DESCRIPTION
          end
        end
      end
    end
  end
end
