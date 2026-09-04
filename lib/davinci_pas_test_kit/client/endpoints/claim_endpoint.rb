require_relative '../user_input_response'
require_relative '../response_generator'
require_relative '../client_urls'
require_relative '../jobs/send_pas_subscription_notification'
require_relative '../../cross_suite/fhirpath_utils'
require_relative '../../cross_suite/response_selection_utils'
require 'subscriptions_test_kit'
require 'udap_security_test_kit'

module DaVinciPASTestKit
  class ClaimEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
    include ResponseGenerator
    include ClientURLs
    include FhirpathUtils
    include ResponseSelectionUtils

    # override the one from URLs to make it version specific
    def suite_id
      request.path.split('/custom/')[1].split('/')[0] # request.path = {base inferno path}/custom/{suite_id}/...
    end

    def test_run_identifier
      return request.params[:session_path] if request.params[:session_path].present?

      UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
        request.headers['authorization']&.delete_prefix('Bearer ')
      )
    end

    def tags
      operation_tag = operation == 'submit' ? SUBMIT_TAG : INQUIRE_TAG
      workflow_tag = WORKFLOW_TAG_MAP[workflow]

      tag_list = [operation_tag]
      tag_list << workflow_tag if workflow_tag.present?
      tag_list << MUST_SUPPORT_WORKFLOW_TAG if must_support_workflow?
      tag_list << claim_update_request_tag if claim_update_request_tag.present?
      tag_list
    end

    # A unique tag set by each Claim Update wait test (via config option) so that
    # verification tests can reload that specific submission by tag.
    def claim_update_request_tag
      test.config.options[:claim_update_tag]
    end

    # Claim Update wait tests set this so that Inferno never sends a Subscription
    # notification in response to their submission, even when the configured
    # response indicates the request was pended.
    def suppress_notifications?
      test.config.options[:suppress_notifications] == true
    end

    def workflow
      case test.id
      when /.*pended.*/
        :pended
      when /.*denial.*/
        :denial
      when /.*approval.*/
        :approval
      when /.*operation_failure.*/
        :operation_failure
      when /.*processing_error.*/
        :processing_error
      when /.*modification.*/
        :modification
      end
    end

    def must_support_workflow?
      test.id =~ /.*must_support.*/ || test.id =~ /.*gather_must_support.*/
    end

    WORKFLOW_TAG_MAP = {
      pended: PENDED_WORKFLOW_TAG,
      denial: DENIAL_WORKFLOW_TAG,
      approval: APPROVAL_WORKFLOW_TAG,
      operation_failure: OPERATION_FAILURE_WORKFLOW_TAG,
      processing_error: PROCESSING_ERROR_WORKFLOW_TAG,
      modification: MODIFICATION_WORKFLOW_TAG
    }.freeze

    def make_response
      return if response.status == 401 # set in update_result (expired token handling there)

      response.format = :json

      # Handle the operation failure and processing error workflows, which require a user-provided response.
      if workflow == :operation_failure
        make_operation_failure_response
        return
      end

      if workflow == :processing_error
        make_processing_error_response
        return
      end

      response.status = 200

      req_bundle = FHIR.from_contents(request.body.string)
      claim_entry = req_bundle&.entry&.find { |e| e&.resource&.resourceType == 'Claim' }
      claim_full_url = claim_entry&.fullUrl
      if claim_entry.blank? || claim_full_url.blank?
        handle_missing_required_elements(claim_entry, response)
        return
      end

      user_inputted_response = resolve_user_response(req_bundle)
      if user_inputted_response.present?
        generated_claim_response_uuid = nil
        response_bundle_json = update_tester_provided_response(user_inputted_response, claim_full_url, operation,
                                                               ig_version)
      else
        decision = # always use the workflow, except for pended when the inquire will get approved
          if operation == 'inquire' && workflow == :pended
            :approval
          else
            workflow
          end
        generated_claim_response_uuid = SecureRandom.uuid
        response_bundle_json = mock_response_bundle(req_bundle, operation, decision, generated_claim_response_uuid,
                                                    ig_version)
      end

      response.body = response_bundle_json

      # Claim Update wait tests must never trigger a Subscription notification,
      # even if the tester supplies a pended response body.
      return if suppress_notifications?
      return unless workflow == :pended && operation == 'submit'

      start_notification_job(response_bundle_json, :approval, generated_claim_response_uuid)
    end

    def update_result
      if UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)
        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
        return
      end

      results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
    end

    # Determines the IG version from the suite_id
    def ig_version
      @ig_version ||= suite_id.include?('v221') ? 'v2.2.1' : 'v2.0.1'
    end

    private

    # Resolves the user-provided response, using criteria-based selection for must support
    # workflows or the single-response approach for other workflows.
    def resolve_user_response(req_bundle)
      if must_support_workflow?
        select_must_support_response(req_bundle)
      else
        UserInputResponse.user_inputted_response(test, operation, result)
      end
    end

    # Selects the first tester-provided response candidate whose selection criteria all
    # match the incoming request, extracts its response Bundle (unwrapping it when the
    # candidate pairs the Bundle with criteria), and replaces {{fhirpath}} tokens with
    # values from the request. Returns nil, causing Inferno to generate a default
    # response, if no candidates are provided or none match. Problems with the
    # tester-provided input or the FHIRPath service also result in nil, with a warning
    # on the waiting test so that the tester can see what went wrong.
    def select_must_support_response(req_bundle)
      candidates = UserInputResponse.response_candidates(result, operation)
      return if candidates.blank?

      operation_url_suffix = "$#{operation}"
      request_number = count_previous_successful_requests(operation_url_suffix) + 1
      selected_index = candidates.index { |candidate| include_entity?(candidate, req_bundle, request_number) }

      if selected_index.nil?
        Inferno::Application['logger'].info(
          "No tester-provided response bundle matched #{operation_url_suffix} request ##{request_number}. " \
          'Inferno will generate a default response.'
        )
        return
      end

      Inferno::Application['logger'].info(
        "Selected tester-provided response bundle #{selected_index + 1} of #{candidates.length} " \
        "for #{operation_url_suffix} request ##{request_number}."
      )
      replace_tokens(entity_bundle(candidates[selected_index]), req_bundle)
    rescue UserInputResponse::InvalidInputError, FhirpathUtils::FhirpathServiceError => e
      add_result_warning(
        "Unable to select a tester-provided response, so Inferno will generate a default response. #{e.message}"
      )
      nil
    end

    # Replaces {{fhirpath}} tokens using values from the incoming request, round-tripping
    # the result through the FHIR model to normalize it. If a replaced value breaks the
    # JSON structure, the result cannot be returned as a FHIR response, so nil is returned
    # with a warning on the waiting test and Inferno generates a default response.
    def replace_tokens(bundle_hash, req_bundle)
      bundle_json = bundle_hash.to_json
      replaced = replace_tokens_in_string(bundle_json, req_bundle)
      return bundle_json if replaced.equal?(bundle_json)

      FHIR.from_contents(replaced)&.to_json || replaced
    rescue JSON::ParserError
      add_result_warning(
        'Unable to use the selected tester-provided response, so Inferno will generate a default response. ' \
        'The response is not valid JSON after {{fhirpath}} token replacement, for example because a token ' \
        'value contains a double quote.'
      )
      nil
    end

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

    def make_operation_failure_response
      user_provided_oo = UserInputResponse.user_inputted_response(test, operation, result)
      unless user_provided_oo.present?
        response.status = 400
        response.body = FHIR::OperationOutcome.new(
          issue: FHIR::OperationOutcome::Issue.new(
            severity: 'fatal', code: 'required',
            details: FHIR::CodeableConcept.new(
              text: 'The operation_failure_operation_outcome input is required for this test and was not provided.'
            )
          )
        ).to_json
        return
      end

      http_status_str = UserInputResponse.read_input(result, 'operation_failure_http_status')
      http_status = http_status_str.present? ? http_status_str.to_i : 400
      http_status = 400 unless (400..599).include?(http_status)

      response.status = http_status
      response.body = user_provided_oo
    end

    def make_processing_error_response
      user_provided_bundle = UserInputResponse.user_inputted_response(test, operation, result)
      unless user_provided_bundle.present?
        response.status = 400
        response.body = FHIR::OperationOutcome.new(
          issue: FHIR::OperationOutcome::Issue.new(
            severity: 'fatal', code: 'required',
            details: FHIR::CodeableConcept.new(
              text: 'The processing_error_response input is required for this test and was not provided.'
            )
          )
        ).to_json
        return
      end

      response.status = 200
      response.body = user_provided_bundle
    end

    def operation
      request.path.split('$').last
    end

    def start_notification_job(response_bundle_json, decision, generated_claim_response_uuid)
      notification_bearer_token = client_access_token_input(result)
      notification_contents = notification_json(response_bundle_json, decision, generated_claim_response_uuid)

      Inferno::Jobs.perform(Jobs::SendPASSubscriptionNotification, test_run.id, test_run.test_session_id, result.id,
                            notification_bearer_token, notification_contents, test_run_identifier, suite_id,
                            ig_version)
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
                                               decision, ig_version)
      else # assume id-only since empty not allowed - if asked for empty, other failures will occur
        mock_id_only_notification_bundle(response_bundle_json, subscription_reference, subscription_topic,
                                         ig_version)
      end
    end

    def find_subscription_content_type(subscription)
      content_ext = subscription.dig('channel', '_payload', 'extension')
        &.find do |ext|
          ext['url'] == 'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content'
        end
      content_ext&.dig('valueCode')
    end
  end
end
