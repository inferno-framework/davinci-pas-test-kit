require_relative '../user_input_response'
require_relative '../response_generator'
require_relative '../subscription_notification_trigger'
require_relative '../client_urls'
require_relative '../../cross_suite/fhirpath_utils'
require_relative '../../cross_suite/response_selection_utils'
require 'subscriptions_test_kit'
require 'udap_security_test_kit'

module DaVinciPASTestKit
  class ClaimEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
    include ResponseGenerator
    include SubscriptionNotificationTrigger
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
      # Requests rejected for an expired token or a rejected $inquire are not treated as
      # submissions of any workflow.
      return [] if UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request) || !operation_enabled?

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

    # Tests must opt in to each operation with the submit_enabled and inquire_enabled options. Inferno responds
    # to every request for an operation that is not enabled with an OperationOutcome, without tagging the
    # request or continuing the test.
    def operation_enabled?
      %w[inquire submit].include?(operation) && test.config.options[:"#{operation}_enabled"] == true
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
      test.id =~ /.*must_support.*/
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

      unless operation_enabled?
        make_rejected_operation_response
        return
      end

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
      @req_bundle = req_bundle # so #tester_notification_bundle can evaluate {{fhirpath}} tokens against it
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
      trigger_notification_if_needed(response_bundle_json, generated_claim_response_uuid)
    end

    # Claim Update wait tests must never trigger a Subscription notification, even if the tester
    # supplies a pended response body (suppress_notifications?). Both the pended workflow and a must
    # support candidate that requests one go through the same start_notification_job call - the
    # difference between them (a single notification_bundle input vs. a candidate-selected
    # ms_notification_bodies entry) is resolved by #tester_notification_bundle.
    def trigger_notification_if_needed(response_bundle_json, generated_claim_response_uuid)
      return if suppress_notifications?
      return unless operation == 'submit'
      return unless workflow == :pended || must_support_notification_ready?(response_bundle_json)

      start_notification_job(response_bundle_json, :approval, generated_claim_response_uuid)
    end

    def update_result
      if UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)
        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
        return
      end
      return unless operation_enabled? # keep waiting for the request that the test is looking for

      results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
    end

    # Determines the IG version from the suite_id
    def ig_version
      @ig_version ||= suite_id.include?('v221') ? 'v2.2.1' : 'v2.0.1'
    end

    private

    # Resolves the user-provided response, using criteria-based selection for must support
    # workflows or the single-response approach for other workflows
    # and replaces {{fhirpath}} tokens with values from the request.
    def resolve_user_response(req_bundle)
      user_response = if must_support_workflow?
                        select_must_support_response(req_bundle)
                      else
                        UserInputResponse.user_inputted_response(test, operation, result)
                      end

      return nil unless user_response.present?

      replace_tokens(user_response, req_bundle)
    rescue FhirpathUtils::FhirpathServiceError => e
      add_result_warning(
        'Unable to instantiate a tester-provided response, so Inferno will generate a default response: ' \
        "#{e.message}"
      )
      nil
    end

    # Selects the first tester-provided response candidate whose selection criteria all
    # match the incoming request, extracts its response Bundle (unwrapping it when the
    # candidate pairs the Bundle with criteria). Returns nil, causing Inferno to generate a default
    # response, if no candidates are provided or none match. Problems with the
    # tester-provided input or the FHIRPath service also result in nil, with a warning
    # on the waiting test so that the tester can see what went wrong.
    def select_must_support_response(req_bundle)
      candidates = UserInputResponse.response_candidates(test, operation, result)
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
      @selected_ms_candidate = candidates[selected_index]
      entity_bundle(@selected_ms_candidate)
    rescue UserInputResponse::InvalidInputError, FhirpathUtils::FhirpathServiceError => e
      add_result_warning(
        'Unable to select a tester-provided response, so Inferno will generate a default response: ' \
        "#{e.message}"
      )
      nil
    end

    # Replaces {{fhirpath}} tokens using values from the incoming request, round-tripping
    # the result through the FHIR model to normalize it. The response may be a parsed hash
    # (must support workflow) or the raw JSON string of a single input. If a replaced value
    # breaks the JSON structure, the result cannot be returned as a FHIR response, so nil is
    # returned with a warning on the waiting test and Inferno generates a default response.
    def replace_tokens(bundle_hash, req_bundle)
      bundle_json = bundle_hash.is_a?(String) ? bundle_hash : bundle_hash.to_json
      replace_tokens_and_normalize(bundle_json, req_bundle)
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
      unless UserInputResponse.user_inputted_response(test, operation, result).present?
        error_outcome_response('The processing_error_response input is required for this test and was not provided.')
        return
      end

      req_bundle = FHIR.from_contents(request.body.string)
      if req_bundle.blank?
        handle_missing_required_elements(nil, response)
        return
      end

      # Unlike other workflows, there is no mocked response to fall back to when instantiation fails.
      instantiated_response = resolve_user_response(req_bundle)
      if instantiated_response.blank?
        error_outcome_response('The processing_error_response input could not be instantiated. ' \
                               'See the warnings on the waiting test for details.')
        return
      end

      claim_entry = req_bundle.entry&.find { |e| e&.resource&.resourceType == 'Claim' }
      response.status = 200
      response.body = update_tester_provided_response(instantiated_response, claim_entry&.fullUrl, operation,
                                                      ig_version)
    end

    def make_rejected_operation_response
      response.status = 501
      response.body = FHIR::OperationOutcome.new(
        issue: FHIR::OperationOutcome::Issue.new(
          severity: 'error', code: 'not-supported',
          details: FHIR::CodeableConcept.new(
            text: "Inferno does not support the $#{operation} operation during this test."
          )
        )
      ).to_json
    end

    def error_outcome_response(text)
      response.status = 400
      response.body = FHIR::OperationOutcome.new(
        issue: FHIR::OperationOutcome::Issue.new(
          severity: 'fatal', code: 'required', details: FHIR::CodeableConcept.new(text:)
        )
      ).to_json
    end

    def operation
      request.path.split('$').last
    end

    # Whether a must support $submit response should trigger a Subscription notification, per the
    # selected response candidate's "notification" key (see AbstractGatherMustSupportTest) - as for a
    # pended decision that is later finalized. False if no candidate was selected, the selected
    # candidate has no "notification" key, the client has not yet created a Subscription for Inferno
    # to notify, or (for a numeric "notification") the index has no corresponding
    # ms_notification_bodies entry. When true, #tester_notification_bundle returns the tester-provided
    # override this resolved (if any), for #start_notification_job to send exactly as it would for the
    # pended workflow's single notification_bundle input.
    def must_support_notification_ready?(response_bundle_json)
      return false unless must_support_workflow?

      notification = selected_ms_notification
      return false if notification.blank?

      if client_subscription_json.blank?
        add_result_warning(
          'A must support response candidate requested a Subscription notification, but the client system ' \
          'has not created a Subscription yet, so no notification will be sent.'
        )
        return false
      end

      unless pended_response?(response_bundle_json)
        add_result_info(
          'Sending a Subscription notification for a must support $submit response that does not appear to ' \
          'indicate a pended decision (no ClaimResponse item adjudication with reviewActionCode ' \
          "'#{PENDED_REVIEW_ACTION_CODE}'). A conformant PAS payer only sends a Subscription notification to " \
          'finalize a previously pended claim.'
        )
      end

      return true if notification == 'generate'

      @ms_notification_override = ms_notification_body_for_index(notification)
      @ms_notification_override.present?
    end

    def selected_ms_notification
      entity_notification(@selected_ms_candidate) if @selected_ms_candidate
    end

    # The raw tester-provided notification body at the 1-based index given by the selected
    # candidate's "notification" value. Warns and returns nil if the index does not correspond to an
    # entry in the ms_notification_bodies input.
    def ms_notification_body_for_index(notification)
      index = notification.to_s.to_i
      bodies = ms_notification_bodies
      if index < 1 || index > bodies.length
        add_result_warning(
          "The \"notification\" value #{notification.inspect} on the selected must support response candidate " \
          "does not correspond to an entry in the '#{UserInputResponse.input_title(test, :ms_notification_bodies)}' " \
          'input. No notification will be sent.'
        )
        return
      end

      bodies[index - 1].to_json
    end

    def ms_notification_bodies
      @ms_notification_bodies ||= begin
        input_value = UserInputResponse.read_input(result, 'ms_notification_bodies')
        parsed = input_value.present? ? JSON.parse(input_value) : []
        parsed.is_a?(Array) ? parsed : [parsed]
      rescue JSON::ParserError
        add_result_warning(
          "The '#{UserInputResponse.input_title(test, :ms_notification_bodies)}' input is not valid JSON."
        )
        []
      end
    end

    # Helper methods for SubscriptionNotificationTrigger

    def notification_test_run_id
      test_run.id
    end

    def notification_test_session_id
      test_run.test_session_id
    end

    def notification_result_id
      result.id
    end

    # These two use the safe UserInputResponse reader rather than SubscriptionSimulationUtils'
    # client_access_token_input/notification_bundle_input, which raise when the waiting test has no
    # "client_endpoint_access_token"/"notification_bundle" input at all - true for the must support
    # gather test, which offers its own ms_notification_bodies input instead (see
    # #must_support_notification_ready?) and has no equivalent to client_endpoint_access_token.
    def notification_bearer_token
      UserInputResponse.read_input(result, :client_endpoint_access_token)
    end

    # The must support workflow selects its override from ms_notification_bodies (resolved by
    # #must_support_notification_ready? into @ms_notification_override) instead of the single
    # notification_bundle input other workflows use - either way, this is the one place
    # SubscriptionNotificationTrigger asks whether there is a tester-provided notification to send.
    def tester_notification_bundle
      notification_json =
        if must_support_workflow?
          @ms_notification_override
        else
          UserInputResponse.read_input(result, :notification_bundle)
        end
      replace_notification_tokens(notification_json)
    end

    # Replaces {{fhirpath}} tokens in a tester-provided notification body using values from the
    # $submit request it is finalizing, the same way as a tester-provided response candidate. If a
    # replaced value breaks the JSON structure, nil is returned with a warning on the waiting test so
    # that Inferno generates a notification instead (see #tester_notification_bundle's caller,
    # SubscriptionNotificationTrigger#notification_json).
    def replace_notification_tokens(notification_json)
      return notification_json if notification_json.blank?

      replace_tokens_and_normalize(notification_json, @req_bundle)
    rescue JSON::ParserError
      add_result_warning(
        'Unable to use the provided notification body, so Inferno will generate one instead. The notification ' \
        'is not valid JSON after {{fhirpath}} token replacement, for example because a token value contains a ' \
        'double quote.'
      )
      nil
    end

    def client_subscription_json
      find_subscription(test_run.test_session_id, as_json: true)
    end
  end
end
