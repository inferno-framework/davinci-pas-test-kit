require 'subscriptions_test_kit'
require_relative '../../../cross_suite/pas_bundle_validation'
require_relative '../../../cross_suite/pas_notification_verification'
require_relative '../../../cross_suite/tags'
require_relative '../../../cross_suite/validator_configuration'
require_relative '../../pended_response_detection'
require_relative '../../subscription_notification_trigger'
require_relative '../../subscription_setup_requirement'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Shared handling of the notifications Inferno sends during the must support workflow, one after each
    # $submit request it returned a pended response to. Each notification is linked to that request by a tag
    # (see DaVinciPASTestKit.notification_link_tag).
    module MustSupportNotificationHelper
      NO_PENDED_RESPONSES_MESSAGE =
        'Inferno did not return any pended responses to must support $submit requests, so it sent no ' \
        'notifications to check.'.freeze

      # Yields each pended must support $submit request with the notification Inferno sent after it, and a
      # label identifying them to the tester. Omits the test if no responses were pended and skips it if any
      # pended request has no notification, so that the test can't pass without checking every notification.
      # @yieldparam submit_request [Inferno::Entities::Request]
      # @yieldparam notification [Inferno::Entities::Request]
      # @yieldparam label [String]
      def each_must_support_notification
        notifications = load_tagged_requests(MUST_SUPPORT_NOTIFICATION_TAG)
        pended_requests = pended_submit_requests
        omit_if pended_requests.empty?, NO_PENDED_RESPONSES_MESSAGE

        unnotified = pended_requests.reject { |submit_request| notification_for(submit_request, notifications) }
        skip_if unnotified.present?, missing_notifications_message(unnotified)

        pended_requests.each do |submit_request|
          yield submit_request, notification_for(submit_request, notifications), label_for(submit_request)
        end
      end

      # Successful must support $submit requests, numbered as Inferno numbers them when selecting responses
      # and notifications by request range.
      def successful_submit_requests
        @successful_submit_requests ||=
          Inferno::Repositories::Requests.new.tagged_requests(test_session_id, [MUST_SUPPORT_WORKFLOW_TAG, SUBMIT_TAG])
            .select { |req| req.status == 200 }
            .sort_by(&:index)
      end

      def pended_submit_requests
        successful_submit_requests.select { |req| PendedResponseDetection.pended?(req.response_body) }
      end

      def notification_for(submit_request, notifications)
        link_tag = submit_request.tags.find { |tag| tag.start_with?(NOTIFICATION_LINK_TAG_PREFIX) }
        link_tag.present? ? notifications.find { |notification| notification.tags.include?(link_tag) } : nil
      end

      def label_for(submit_request)
        "Notification for $submit request #{successful_submit_requests.index(submit_request) + 1}"
      end

      def missing_notifications_message(unnotified)
        request_numbers = unnotified.map { |req| successful_submit_requests.index(req) + 1 }.join(', ')
        "Inferno did not send a notification after the pended response to $submit request(s) #{request_numbers}. " \
          'This happens when there is no Subscription to send it to, or when the *Demonstrate Must Support ' \
          'Coverage* wait ends before Inferno sends it, which takes about 5-10 seconds after the response. ' \
          'Check the messages on the waiting test, then re-run the *Demonstrate Must Support Coverage* group.'
      end

      # Prefixes the messages added in the block with the label, so that the tester can tell which notification
      # each is about. Message lines are moved to the left margin so that the label doesn't turn indented message
      # text into a markdown code block.
      def with_message_label(label)
        first_new_message = messages.length
        yield
      rescue Inferno::Exceptions::AssertionException => e
        # A notification too malformed to check further shouldn't stop the others from being checked
        add_message('error', e.message)
      ensure
        messages[first_new_message..].each do |message|
          message[:message] = "#{label}: #{message[:message].strip.gsub(/\n[ \t]+/, "\n")}"
        end
      end
    end

    class PASClientMustSupportNotificationConformanceTest < Inferno::Test
      include SubscriptionsTestKit::NotificationConformanceVerification
      include MustSupportNotificationHelper

      id :pas_client_v221_ms_notification_conformance_test
      title 'Inferno\'s must support event notification Bundles are conformant'
      description %(
        This test checks that each notification Bundle sent to the PAS client after a pended `$submit`
        response during the *Demonstrate Must Support Coverage* group, which will be either selected from
        the tester-provided **Must Support Notification Bundles** input or mocked by Inferno, is conformant
        to Subscription Backport IG requirements, including those of the payload content requested in the
        Subscription. To ensure that the PAS client is driving its behavior only based on standard
        information, custom extensions are not allowed within the notification Bundle.
      )
      simulation_verification

      run do
        subscription = SubscriptionSetupRequirement.created_subscription(test_session_id)
        each_must_support_notification do |_submit_request, notification, label|
          with_message_label(label) do
            notification_verification(notification.request_body, 'event-notification',
                                      validator: NO_CUSTOM_EXTENSIONS_VALIDATOR)
            verify_payload_content(notification.request_body, subscription)
          end
        end

        assert_no_error_messages('The must support event notifications are not conformant - see messages.')
      end

      def verify_payload_content(notification_body, subscription)
        content_type = SubscriptionNotificationTrigger.subscription_content_type(subscription) if subscription.present?
        case content_type
        when 'full-resource'
          full_resource_event_notification_verification(notification_body, nil)
        when 'id-only'
          id_only_event_notification_verification(notification_body, nil)
        when 'empty'
          empty_event_notification_verification(notification_body)
        else
          add_message('warning', 'The payload content could not be checked because the Subscription does not ' \
                                 'have a recognized payload content code.')
        end
      end
    end

    class PASClientMustSupportNotificationPASConformanceTest < Inferno::Test
      include PasBundleValidation
      include PASNotificationVerification
      include MustSupportNotificationHelper

      id :pas_client_v221_ms_notification_pas_conformance_test
      title 'Inferno\'s must support notifications conform to PAS-specific requirements'
      description DaVinciPASTestKit.notification_pas_conformance_description(
        'selected from the tester-provided **Must Support Notification Bundles** input or mocked by Inferno ' \
        'after a pended `$submit` response during the *Demonstrate Must Support Coverage* group'
      ) + <<~CORRESPONDENCE

        This test also warns when the ClaimResponse in a notification shares neither an id nor an identifier
        with the ClaimResponse in the pended response it follows, since the PAS client may then be unable to
        connect the final decision to the pended request. Responses and notifications are selected separately,
        so check that their selection criteria pair them as intended.
      CORRESPONDENCE
      simulation_verification

      run do
        each_must_support_notification do |submit_request, notification, label|
          with_message_label(label) do
            check_pas_notification(notification.request_body, focus_validator: NO_CUSTOM_EXTENSIONS_VALIDATOR,
                                                              echoed_from: submit_request.request_body)
            check_correspondence(submit_request, notification)
          end
        end

        assert_no_error_messages('The must support notifications do not conform to PAS requirements - ' \
                                 'see messages.')
      end

      def check_correspondence(submit_request, notification)
        pended = claim_response_in(FHIR.from_contents(submit_request.response_body))
        final = claim_response_in(notification_focus_bundle(notification.request_body))
        return if pended.blank? || final.blank? || corresponding?(pended, final)

        add_message('warning', "The notification's ClaimResponse (id `#{final.id}`) shares neither an id nor an " \
                               "identifier with the ClaimResponse in the pended response (id `#{pended.id}`), so " \
                               'the PAS client may not be able to connect the final decision to the pended request.')
      end

      def corresponding?(pended, final)
        return true if pended.id.present? && pended.id == final.id

        identifier_keys(pended).intersect?(identifier_keys(final))
      end

      def identifier_keys(claim_response)
        Array(claim_response.identifier).filter_map do |identifier|
          "#{identifier.system}|#{identifier.value}" if identifier.value.present?
        end
      end

      # The first Bundle in the notification after its SubscriptionStatus, which a PAS notification's focus is
      def notification_focus_bundle(notification_body)
        notification = FHIR.from_contents(notification_body)
        return unless notification.is_a?(FHIR::Bundle)

        Array(notification.entry).drop(1).map(&:resource).find { |resource| resource.is_a?(FHIR::Bundle) }
      end

      def claim_response_in(bundle)
        return unless bundle.is_a?(FHIR::Bundle)

        Array(bundle.entry).map(&:resource).find { |resource| resource.is_a?(FHIR::ClaimResponse) }
      end
    end

    class PASClientMustSupportNotificationAcceptanceTest < Inferno::Test
      include MustSupportNotificationHelper

      id :pas_client_v221_ms_notification_acceptance_test
      title 'PAS client accepts the must support event notifications'
      description %(
        This test checks that the PAS client responded successfully to each event notification Inferno
        sent after a pended `$submit` response during the *Demonstrate Must Support Coverage* group.
      )

      run do
        each_must_support_notification do |_submit_request, notification, label|
          # The notification job records a nil status if the request fails entirely
          if notification.status.nil?
            add_message('error', "#{label}: the request failed with error: #{notification.response_body}")
          elsif !notification.status.between?(200, 299)
            add_message('error', "#{label}: the PAS client responded with status code #{notification.status}.")
          end
        end

        assert_no_error_messages('The PAS client did not accept all must support event notifications - ' \
                                 'see messages.')
      end
    end
  end
end
