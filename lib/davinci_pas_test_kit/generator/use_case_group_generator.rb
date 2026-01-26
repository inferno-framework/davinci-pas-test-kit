module DaVinciPASTestKit
  class Generator
    class UseCaseGroupGenerator
      class << self
        def generate(ig_metadata, base_metadata_output_dir, base_server_output_dir)
          groups = ig_metadata.groups.select { |group| group.tests.present? }.reject do |group|
            group.profile_name.include?('Base')
          end
          # Server Test Groups
          ['approval', 'denial', 'pended'].each_with_index do |use_case, index|
            new(ig_metadata, use_case, groups, base_server_output_dir, base_metadata_output_dir, 'server',
                first_generate: index.zero?).generate
          end
        end
      end

      attr_accessor :ig_metadata, :use_case, :groups, :base_output_dir, :base_metadata_output_dir,
                    :first_generate, :system

      def initialize(ig_metadata, use_case, groups, base_output_dir, base_metadata_output_dir,
                     system = 'server', first_generate: false)
        self.ig_metadata = ig_metadata
        self.use_case = use_case
        self.groups = groups
        self.base_output_dir = base_output_dir
        self.base_metadata_output_dir = base_metadata_output_dir
        self.system = system
        self.first_generate = first_generate
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
        "DaVinciPAS#{groups.first.reformatted_version.upcase}"
      end

      def title
        "Successful #{use_case.capitalize} Workflow"
      end

      def output_file_name
        File.join(base_output_dir, base_output_file_name)
      end

      def metadata_file_dir(group)
        File.join(base_metadata_output_dir, profile_identifier(group))
      end

      def metadata_file_name(group)
        File.join(base_metadata_output_dir, profile_identifier(group), base_metadata_file_name)
      end

      def profile_identifier(group_metadata)
        ig_metadata.snake_case_for_profile(group_metadata)
      end

      def group_id
        "pas_#{system}_#{groups.first.reformatted_version}_#{use_case}_use_case"
      end

      def generate
        FileUtils.mkdir_p(base_output_dir)
        File.write(output_file_name, output)
        ig_metadata.add_use_case_groups(group_id, base_output_file_name)
        return unless first_generate

        groups.each do |group_metadata|
          FileUtils.mkdir_p(metadata_file_dir(group_metadata))
          File.write(metadata_file_name(group_metadata), YAML.dump(group_metadata.to_hash))
        end
      end

      def all_tests
        @all_tests ||= groups.flat_map(&:tests).compact
      end

      def all_test_ids
        @all_test_ids = all_tests.map { |test| test[:id] }
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

      def subscription_notification_conformance_test_ids
        ['subscriptions_r4_server_notification_conformance', 'subscriptions_r4_server_id_only_conformance']
      end

      def grouped_pended_test_ids
        inquiry_operation = [inquiry_notification_test_id] +
                            subscription_notification_conformance_test_ids +
                            inquiry_request_validation_test_ids +
                            inquiry_operation_test_ids +
                            inquiry_response_validation_test_ids
        inquiry_tests = {
          'Server can notify client of updates and respond to claims submitted for inquiry' => inquiry_operation
        }

        grouped_approval_denial_test_ids.merge(inquiry_tests)
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

      def test_id_list
        @test_id_list ||= if ['approval', 'denial'].include?(use_case)
                            grouped_approval_denial_test_ids
                          elsif use_case == 'pended'
                            grouped_pended_test_ids
                          end
      end

      def test_file_list
        @test_file_list ||= if ['approval', 'denial'].include?(use_case)
                              approval_denial_test_file_list
                            elsif use_case == 'pended'
                              pended_test_file_list
                            end
      end

      def claim_response_decision_test_id
        'prior_auth_claim_response_decision_validation'
      end

      def inquiry_notification_test_id
        'prior_auth_claim_response_update_notification_validation'
      end

      def claim_response_decision_file_name
        "../../#{ig_metadata.ig_version}/claim_response_decision/pas_claim_response_decision_test"
      end

      def subscription_notification_file_name
        "../../#{ig_metadata.ig_version}/notification/pas_subscription_notification_test"
      end

      def rename_input?(test_id)
        (test_id.include?('request') && test_id.include?('validation') && !test_id.include?('inquiry')) ||
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
    end
  end
end
