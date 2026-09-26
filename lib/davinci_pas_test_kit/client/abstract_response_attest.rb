module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractResponseAttest < Inferno::Test
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

    def tags_to_load
      [workflow_tag, operation_tag].compact
    end

    def workflow_name
      case workflow_tag
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
      else
        raise Inferno::Exceptions::TestSuiteImplementationException.new('PAS Display Attestation',
                                                                        "No name for workflow tag #{workflow_tag}.")
      end
    end

    output :attest_true_url
    output :attest_false_url

    run do
      # check that there are actually requests
      # - skip if none unless there is a config
      # - raise an implementation error if there are more than 1 unless config set (shouldn't ever)
      # - skip if one that is a failure HTTP status unless config set

      requests = load_tagged_requests(*tags_to_load)
      if requests.empty?
        if config.options[:no_requests_ok]
          pass 'Attestation not needed: no requests received or required for this group.'
        else
          skip "Skipping attestation: No requests made demonstrating the #{workflow_name} workflow."
        end
      elsif requests.one?
        is_success_response = requests.first.status.to_s.start_with?('2')
        if is_success_response && config.options[:error_status_expected]
          skip 'Skipping attestation: Inferno expected to return a HTTP error response, but did not.'
        elsif !is_success_response && !config.options[:error_status_expected]
          skip 'Skipping attestation: Inferno expected to return a succesful response, but did not.'
        end
      elsif !config.options[:multiple_requests_ok]
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'PAS request tagging',
          "multiple requests tagged with workflow tag #{workflow_tag}."
        )
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
