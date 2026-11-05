require_relative '../../abstract_gather_must_support_test'
require_relative '../../pended_response_detection'
require_relative '../../subscription_setup_requirement'
require_relative '../../client_input_descriptions'
require_relative '../../../cross_suite/response_selection_utils'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientGatherMustSupportTest < AbstractGatherMustSupportTest
      include URLs
      include SubscriptionSetupRequirement

      id :pas_client_v221_gather_must_support

      input :ms_submit_notifications,
            title: 'Must Support Notification Bundles',
            type: 'textarea',
            optional: true,
            description: MS_NOTIFICATIONS_INPUT_DESCRIPTION
      input :client_endpoint_access_token,
            optional: true,
            title: 'Client Notification Access Token',
            description: %(
              The bearer token that Inferno will send on requests to the PAS client's rest-hook notification
              endpoint when notifying it of the final decision on pended `$submit` requests. Not needed if the
              PAS client created a Subscription with an appropriate header value in the `channel.header` element.
              If a value for the `authorization` header is provided in `channel.header`, this value will override it.
            )

      # Inferno only pends must support $submit requests when the tester provides pended responses, and then
      # notifies the PAS client of the final decision, which needs the Subscription the PAS client created.
      def check_notification_prerequisites
        return unless pended_responses_provided?

        require_unmodified_subscription(skip_message: MS_PENDED_NO_SUBSCRIPTION_SKIP_MESSAGE,
                                        modified_skip_message: MS_PENDED_MODIFIED_SUBSCRIPTION_SKIP_MESSAGE)
      end

      def notification_description_for_wait
        <<~DESCRIPTION.strip
          ### Notifications

          #{notification_behavior_for_wait}
        DESCRIPTION
      end

      def notification_behavior_for_wait
        unless pended_responses_provided?
          return "None of the responses in the '**#{input_title(:ms_submit_responses)}**' input pend the " \
                 'prior authorization decision, so Inferno will not send notifications.'
        end

        source = if ms_submit_notifications.present?
                   "selected from the '**#{input_title(:ms_submit_notifications)}**' input in the same way " \
                     'as responses, or mocked by Inferno if no entry matches'
                 else
                   'mocked by Inferno from the pended response'
                 end
        'After returning a pended response to a `$submit` request, Inferno will send a full-resource notification ' \
          "with the final decision to the PAS client's Subscription endpoint. The notification will be #{source}. " \
          'Inferno sends each notification about 5-10 seconds after the pended response, and does not send it if ' \
          'this wait has ended by then, so wait at least 15 seconds after the last pended response before ' \
          'continuing.'
      end

      # Whether any of the tester-provided $submit responses pend the decision. An unusable input is reported
      # when Inferno tries to use it to respond to a request.
      def pended_responses_provided?
        return @pended_responses_provided if defined?(@pended_responses_provided)

        candidates = UserInputResponse.parse_candidates(self, :ms_submit_responses, ms_submit_responses,
                                                        ResponseSelectionUtils::RESPONSE_RESOURCE_TYPES)
        @pended_responses_provided = Array(candidates).any? do |candidate|
          PendedResponseDetection.pended?(ResponseSelectionUtils.entity_response(candidate))
        end
      rescue UserInputResponse::InvalidInputError
        @pended_responses_provided = false
      end
    end
  end
end
