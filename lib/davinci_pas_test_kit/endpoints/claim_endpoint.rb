require_relative '../user_input_response'
require_relative '../response_generator'
require_relative '../urls'
require_relative '../jobs/send_pas_subscription_notification'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class ClaimEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
    include ResponseGenerator

    def test_run_identifier
      request.headers['authorization']&.delete_prefix('Bearer ')
    end

    def tags
      operation_tag = operation == 'submit' ? SUBMIT_TAG : INQUIRE_TAG
      workflow_tag = WORKFLOW_TAG_MAP[workflow]

      return [operation_tag, workflow_tag] if workflow_tag.present?

      [operation_tag]
    end

    def workflow
      case test.id
      when /.*pended.*/
        :pended
      when /.*denial.*/
        :denial
      when /.*approval.*/
        :approval
      end
    end

    WORKFLOW_TAG_MAP = {
      pended: PENDED_WORKFLOW_TAG,
      denial: DENIAL_WORKFLOW_TAG,
      approval: APPROVAL_WORKFLOW_TAG
    }.freeze

    def make_response
      response.status = 200
      response.format = :json

      start_notification_job if workflow == :pended && operation == 'submit'

      req_bundle = FHIR.from_contents(request.body.string)
      claim_entry = req_bundle&.entry&.find { |e| e&.resource&.resourceType == 'Claim' }
      claim_full_url = claim_entry&.fullUrl
      if claim_entry.blank? || claim_full_url.blank?
        handle_missing_required_elements(claim_entry, response)
        return
      end

      user_inputted_response = UserInputResponse.user_inputted_response(test, operation, result)
      if user_inputted_response.present?
        response.body = update_tester_provided_response(user_inputted_response, claim_full_url)
        return
      end

      decision = # always use the workflow, except for pended when the inquire will get approved
        if operation == 'inquire' && workflow == :pended
          :approval
        else
          workflow
        end
      response.body = mock_response_bundle(req_bundle, operation, decision)
    end

    def update_result
      results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
    end

    private

    def handle_missing_required_elements(claim_entry, response)
      response.status = 400
      details = if claim_entry.blank?
                  'Required Claim entry missing from bundle'
                else
                  'Required element fullUrl missing from Claim entry'
                end
      response.body = FHIR::OperationOutcome.new(
        issue: FHIR::OperationOutcome::Issue.new(severity: 'fatal', code: 'required',
                                                 details: FHIR::CodeableConcept.new(text: details))
      ).to_json
    end

    def operation
      request.url&.split('$')&.last
    end

    def start_notification_job
      notification_json = JSON.parse(result.input_json).find { |i| i['name'] == 'notification_bundle' }['value']
      created_subscription = find_subscription(test_run.test_session_id)
      client_endpoint = created_subscription.channel.endpoint
      bearer_token = client_access_token_input(result)
      fhir_base_url = extract_fhir_base_url(request.url)
      test_suite_base_url = fhir_base_url.chomp('/').chomp('/fhir')
      fhir_subscription_url = test_suite_base_url + FHIR_SUBSCRIPTION_PATH

      Inferno::Jobs.perform(Jobs::SendPASSubscriptionNotification, test_run.id, test_run.test_session_id, result.id,
                            created_subscription.id, fhir_subscription_url, client_endpoint, bearer_token,
                            notification_json, test_run_identifier, test_suite_base_url)
    end
  end
end
