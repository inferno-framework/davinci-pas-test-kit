require_relative '../user_input_response'
require_relative '../response_generator'
require_relative '../urls'
require_relative '../jobs/send_pas_subscription_notification'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class ClaimEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
    include ResponseGenerator
    include URLs

    # override the one from URLs
    def suite_id
      request.path.split('/custom/')[1].split('/')[0] # request.path = {base inferno path}/custom/{suite_id}/...
    end

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

      req_bundle = FHIR.from_contents(request.body.string)
      claim_entry = req_bundle&.entry&.find { |e| e&.resource&.resourceType == 'Claim' }
      claim_full_url = claim_entry&.fullUrl
      if claim_entry.blank? || claim_full_url.blank?
        handle_missing_required_elements(claim_entry, response)
        return
      end

      user_inputted_response = UserInputResponse.user_inputted_response(test, operation, result)
      if user_inputted_response.present?
        generated_claim_response_uuid = nil
        response_bundle_json = update_tester_provided_response(user_inputted_response, claim_full_url)
      else
        decision = # always use the workflow, except for pended when the inquire will get approved
          if operation == 'inquire' && workflow == :pended
            :approval
          else
            workflow
          end
        generated_claim_response_uuid = SecureRandom.uuid
        response_bundle_json = mock_response_bundle(req_bundle, operation, decision, generated_claim_response_uuid)
      end

      response.body = response_bundle_json

      return unless workflow == :pended && operation == 'submit'

      start_notification_job(response_bundle_json, :approval, generated_claim_response_uuid)
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

    def start_notification_job(response_bundle_json, decision, generated_claim_response_uuid)
      notification_bearer_token = client_access_token_input(result)
      notification_contents = notification_json(response_bundle_json, decision, generated_claim_response_uuid)

      Inferno::Jobs.perform(Jobs::SendPASSubscriptionNotification, test_run.id, test_run.test_session_id, result.id,
                            notification_bearer_token, notification_contents, test_run_identifier, suite_id)
    end

    def notification_json(response_bundle_json, decision, generated_claim_response_uuid)
      user_inputted_notification_json =
        JSON.parse(result.input_json).find { |i| i['name'] == 'notification_bundle' }['value']

      if user_inputted_notification_json.present?
        update_tester_provided_notification(user_inputted_notification_json, generated_claim_response_uuid)
      else
        generate_notification(response_bundle_json, decision)
      end
    end

    def generate_notification(response_bundle_json, decision)
      subscription = find_subscription(test_run.test_session_id, as_json: true)
      subscription_reference = "#{fhir_subscription_url}/#{subscription['id']}"
      subscription_topic = subscription['criteria']

      if find_subscription_content_type(subscription) == 'full-resource'
        mock_full_resource_notification_bundle(response_bundle_json, subscription_reference, subscription_topic,
                                               decision)
      else # assume id-only since empty not allowed - if asked for empty, other failures will occur
        mock_id_only_notification_bundle(response_bundle_json, subscription_reference, subscription_topic)
      end
    end

    def find_subscription_content_type(subscription)
      content_ext = subscription['channel']['_payload']['extension']
        .find do |ext|
          ext['url'] == 'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content'
        end
      content_ext['valueCode'] if content_ext.present?
    end
  end
end
