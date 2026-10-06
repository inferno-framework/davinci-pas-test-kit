require_relative 'response_generator'
require_relative 'jobs/send_pas_subscription_notification'

module DaVinciPASTestKit
  # Starts the job that sends a Subscription notification to the client after a pended $submit response.
  # The notification is the tester-provided one (updated to be current) when there is one, or a mocked
  # notification based on the response and the client's Subscription otherwise.
  #
  # The module does not know how to reach the tester's inputs or the requests made earlier in the session,
  # because that differs between the classes that use it (suite endpoints and Inferno tests). Including
  # classes provide them through the helper methods below, which raise NotImplementedError here.
  #
  # Helper methods the including class must provide:
  # - notification_test_run_id, notification_test_session_id, notification_result_id: identify the test run,
  #   session and the waiting result that the job checks on and records the notification request on. The test
  #   run and result ids may be nil when the including class cannot know them yet (an Inferno test that has
  #   not started waiting), in which case the job looks them up.
  # - notification_bearer_token: the access token to send with the notification, from the tester's inputs
  # - tester_notification_bundle: the tester-provided notification Bundle JSON, or nil
  # - client_subscription_json: the Subscription the client created, as parsed JSON (so that primitive
  #   extensions are kept), from the earlier successful Subscription create request. nil if there is none.
  # - test_run_identifier: the token that identifies the waiting test to resume
  # - suite_id and ig_version: the suite that the job should send the notification for, and its IG version
  # - fhir_subscription_url: the base URL of the Subscription endpoint (provided by ClientURLs)
  module SubscriptionNotificationTrigger
    include ResponseGenerator

    HELPERS = %i[notification_test_run_id notification_test_session_id notification_result_id
                 notification_bearer_token tester_notification_bundle client_subscription_json].freeze
    HELPERS.each do |helper|
      define_method(helper) do
        raise NotImplementedError, "#{self.class} must implement ##{helper} to use SubscriptionNotificationTrigger"
      end
    end

    # With resume_test true, the job ends the wait identified by test_run_identifier once it has sent the
    # notification, for use by an Inferno test that waits for the notification to be sent.
    def start_notification_job(response_bundle_json, decision, generated_claim_response_uuid, resume_test: false)
      notification_contents = notification_json(response_bundle_json, decision, generated_claim_response_uuid)

      Inferno::Jobs.perform(Jobs::SendPASSubscriptionNotification, notification_test_run_id,
                            notification_test_session_id, notification_result_id, notification_bearer_token,
                            notification_contents, test_run_identifier, suite_id, ig_version, resume_test)
    end

    private

    def notification_json(response_bundle_json, decision, generated_claim_response_uuid)
      user_inputted_notification_json = tester_notification_bundle

      if user_inputted_notification_json.present?
        update_tester_provided_notification(user_inputted_notification_json, generated_claim_response_uuid)
      else
        generate_notification(response_bundle_json, decision)
      end
    end

    def generate_notification(response_bundle_json, decision)
      subscription = client_subscription_json
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
