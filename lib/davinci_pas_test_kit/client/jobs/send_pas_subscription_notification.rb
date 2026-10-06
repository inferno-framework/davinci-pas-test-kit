# frozen_string_literal: true

require_relative '../../cross_suite/tags'
require_relative '../client_urls'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  module Jobs
    class SendPASSubscriptionNotification
      include Sidekiq::Job
      include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
      include ClientURLs

      # provide a suite_id definition to use with the ClientURLs module
      def suite_id
        @notification_suite_id
      end

      attr_reader :ig_version

      sidekiq_options retry: false

      # How long an Inferno test that starts this job waits for it to send the notification. The job polls for
      # the test to start waiting for up to this long, since there is no point sending once the wait has timed out.
      TEST_WAIT_TIMEOUT_SECONDS = 300
      TEST_WAITING_POLL_INTERVAL_SECONDS = 0.5

      # test_run_id and result_id may be nil when the job is started by an Inferno test, which does not know
      # them until it is waiting. They are then looked up from the test session once the test waits.
      # When resume_test_after_notification is true, the job ends the wait with the resume_token after
      # sending the notification (or fails it if the job errors).
      # Sidekiq job arguments are positional, so the boolean cannot be a keyword argument
      def perform(test_run_id, test_session_id, result_id, notification_bearer_token, notification_json, resume_token,
                  notification_suite_id, ig_version = 'v2.0.1', resume_test_after_notification = false) # rubocop:disable Style/OptionalBooleanParameter
        @test_run_id = test_run_id
        @test_session_id = test_session_id
        @result_id = result_id
        @notification_bearer_token = notification_bearer_token
        @notification_json = notification_json
        @resume_token = resume_token
        @notification_suite_id = notification_suite_id
        @ig_version = ig_version
        @resume_test_after_notification = resume_test_after_notification

        await_subscription_creation # NOTE: currently must exist - see PASClientPendedSubmitTest
        if @result_id.nil? && !test_starts_waiting?
          # the test can't be resumed because it isn't waiting, so just explain why no notification was sent
          Inferno::Application['logger'].error(
            "Subscription notification not sent: no test started waiting on '#{@resume_token}' " \
            "within #{TEST_WAIT_TIMEOUT_SECONDS} seconds."
          )
          return
        end
        sleep 1
        return unless test_still_waiting?

        sleep rand(5..10)
        return unless test_still_waiting?

        send_event_notification
        resume_test(RESUME_PASS_PATH) if @resume_test_after_notification
      rescue StandardError => e
        raise unless @resume_test_after_notification

        Inferno::Application['logger'].error("Sending the subscription notification failed: #{e.message}")
        resume_test(RESUME_FAIL_PATH)
      end

      def requests_repo
        @requests_repo ||= Inferno::Repositories::Requests.new
      end

      def results_repo
        @results_repo ||= Inferno::Repositories::Results.new
      end

      def subscription
        @subscription ||= find_subscription(@test_session_id)
      end

      def subscription_notification_endpoint
        subscription&.channel&.endpoint
      end

      def headers
        @headers ||= subscription_headers.merge(content_type_header).merge(authorization_header)
      end

      def rest_hook_connection
        @rest_hook_connection ||= Faraday.new(url: subscription_notification_endpoint, request: { open_timeout: 30 },
                                              headers:)
      end

      def test_suite_connection
        @test_suite_connection ||= Faraday.new(base_url)
      end

      def content_type_header
        @content_type_header ||= { 'Content-Type' => actual_mime_type(subscription) }
      end

      def subscription_headers
        @subscription_headers ||= subscription.channel&.header&.each_with_object({}) do |header, hash|
          header_name, header_value = header.split(': ', 2)
          hash[header_name] = header_value
        end || {}
      end

      def authorization_header
        @authorization_header ||=
          @notification_bearer_token.present? ? { 'Authorization' => "Bearer #{@notification_bearer_token}" } : {}
      end

      def subscription_topic
        @subscription_topic ||= subscription&.criteria
      end

      def subscription_full_url
        @subscription_full_url ||= "#{fhir_subscription_url}/#{subscription.id}"
      end

      def test_runs_repo
        @test_runs_repo ||= Inferno::Repositories::TestRuns.new
      end

      # @resume_token is the same identifier the test's own wait() call registers (and that
      # resume_test later ends the wait with), so this is an exact match on the waiting test
      # run - not a guess at "the most recent run for this session", which could pick up an
      # unrelated run if the tester has more than one for the same session.
      def test_run_id
        @test_run_id ||= test_runs_repo.find_latest_waiting_by_identifier(@resume_token)&.id
      end

      def waiting_result
        results_repo.find_waiting_result(test_run_id:)
      end

      def result_id
        @result_id ||= waiting_result&.id
      end

      def test_still_waiting?
        waiting_result.present?
      end

      # Inferno tests start the job before they begin waiting, so poll until the test is waiting, giving up
      # once the test's own wait would have timed out.
      # @return [Boolean] whether the test is waiting
      def test_starts_waiting?
        (TEST_WAIT_TIMEOUT_SECONDS / TEST_WAITING_POLL_INTERVAL_SECONDS).to_i.times do
          return true if test_still_waiting?

          sleep TEST_WAITING_POLL_INTERVAL_SECONDS
        end
        test_still_waiting?
      end

      def resume_test(path)
        test_suite_connection.get(path.delete_prefix('/'), { token: @resume_token })
      end

      def await_subscription_creation
        sleep 0.5 until subscription.present? || !test_still_waiting?
      end

      def send_event_notification
        event_json = derive_event_notification(@notification_json, subscription_full_url, subscription_topic,
                                               1).to_json
        response = send_notification(event_json)
        persist_notification_request(response, [REST_HOOK_EVENT_NOTIFICATION_TAG])
      end

      def send_notification(request_body)
        rest_hook_connection.post('', request_body)
      rescue Faraday::Error => e
        # Warning: This is a hack. If there is an error with the request such that we never get a response, we have
        #          no clean way to persist that information for the Inferno test to check later. The solution here
        #          is to persist the request anyway with a status of nil, using the error message as response body
        Faraday::Response.new(response_body: e.message, url: rest_hook_connection.url_prefix.to_s,
                              request_body:, request_headers: headers)
      end

      def persist_notification_request(response, tags)
        inferno_request_headers = headers.map { |name, value| { name:, value: } }
        inferno_response_headers = response.headers&.map { |name, value| { name:, value: } }
        requests_repo.create(
          verb: 'POST',
          url: response.env.url.to_s,
          direction: 'outgoing',
          status: response.status,
          request_body: response.env.request_body,
          response_body: response.env.response_body,
          test_session_id: @test_session_id,
          result_id:,
          request_headers: inferno_request_headers,
          response_headers: inferno_response_headers,
          tags:
        )
      end
    end
  end
end
