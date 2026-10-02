require_relative 'request_count_gating'

module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractResponseAttest < Inferno::Test
    include RequestCountGating

    id :pas_client_response_attest
    title 'PAS client reacts appropriately to the response'
    description %(
      During this test, the tester will observe the client system following
      the receipt of a response and attest that users are able to see the appropriate
      updates to the corresponding prior authorization request in their system.
    )
    attestation

    def workflow_tag
      config.options[:workflow_tag]
    end

    def operation_tag
      config.options[:operation_tag]
    end

    def attest_message
      config.options[:attest_message]
    end

    # workflow_tag may be a single tag or an Array of tags (e.g. the Claim Update attest tests,
    # which match requests across several update steps); normalized to an Array so callers don't
    # each need their own is_a?(Array) check.
    def workflow_tags
      Array(workflow_tag)
    end

    def workflow_name
      case workflow_tags.first
      when APPROVAL_WORKFLOW_TAG
        'Approval'
      when DENIAL_WORKFLOW_TAG
        'Denial'
      when PENDED_WORKFLOW_TAG
        'Pended'
      when MODIFICATION_WORKFLOW_TAG
        'Payer Modification'
      when MUST_SUPPORT_WORKFLOW_TAG
        'Must Support'
      when OPERATION_FAILURE_WORKFLOW_TAG
        'Operation Failure'
      when PROCESSING_ERROR_WORKFLOW_TAG
        'Processing Error'
      when CLAIM_UPDATE_INITIAL_TAG
        'Claim Update'
      else
        raise Inferno::Exceptions::TestSuiteImplementationException.new('PAS Display Attestation',
                                                                        "No name for workflow tag #{workflow_tag}.")
      end
    end

    def target_requests
      workflow_tags.flat_map do |one_workflow_tag|
        load_tagged_requests(*[one_workflow_tag, operation_tag].compact)
      end
    end

    output :attest_true_url
    output :attest_false_url

    run do
      # check that there are actually requests
      # - skip if none unless there is a config
      # - raise an implementation error if there are more than 1 unless config set (shouldn't ever)
      # - skip if one that is a failure HTTP status unless config set

      requests = target_requests
      if requests.empty?
        if no_requests_ok?
          pass 'Attestation not needed: no requests received or required for this group.'
        else
          skip "Skipping attestation: No requests made demonstrating the #{workflow_name} workflow."
        end
      elsif requests.length > 1 && !multiple_requests_ok?
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'PAS request tagging',
          "multiple requests tagged with workflow tag #{workflow_tag}."
        )
      else
        success_responses, error_responses = requests.partition { |r| r.status.to_s.start_with?('2') }
        if success_responses.present? && config.options[:error_status_expected]
          skip 'Skipping attestation: Inferno expected to return a HTTP error response, but did not.'
        elsif error_responses.present? && !config.options[:error_status_expected]
          skip 'Skipping attestation: Inferno expected to return a succesful response, but did not.'
        end
      end

      identifier = test_session_id
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      output(attest_true_url:)
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_false_url:)

      wait(
        identifier:,
        message: %(
          **#{workflow_name} Workflow Test**:

          #{attest_message}

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.
        )
      )
    end
  end
end
