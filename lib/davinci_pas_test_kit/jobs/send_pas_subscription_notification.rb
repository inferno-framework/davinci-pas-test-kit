# frozen_string_literal: true

require_relative '../tags'
require_relative '../urls'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  module Jobs
    class SendPASSubscriptionNotification
      include Sidekiq::Job
      include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
      include URLs

      # override the one from URLs
      def suite_id
        :davinci_pas_client_suite_v201 # TODO: don't hard-code the id here...
      end

      sidekiq_options retry: false

      def perform(test_run_id, test_session_id, result_id, notification_bearer_token, notification_json, resume_token)
        @test_run_id = test_run_id
        @test_session_id = test_session_id
        @result_id = result_id
        @notification_bearer_token = notification_bearer_token
        @notification_json = notification_json
        @resume_token = resume_token

        await_subcription_creation # NOTE: currently must exist - see PASClientPendedSubmitTest
        sleep 1
        return unless test_still_waiting?

        sleep rand(5..10)
        return unless test_still_waiting?

        send_event_notification
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

      def test_still_waiting?
        results_repo.find_waiting_result(test_run_id: @test_run_id)
      end

      def await_subcription_creation
        sleep 0.5 until subscription.present? || !test_still_waiting?
      end

      def send_event_notification
        event_json = derive_event_notification(@notification_json, subscription_full_url, subscription_topic, 1).to_json
        response = send_notification(event_json)
        persist_notification_request(response, [REST_HOOK_EVENT_NOTIFICATION_TAG])
      end

      def resume_inferno_test
        test_suite_connection.get(RESUME_PASS_PATH.delete_prefix('/'), { token: @resume_token })
      end

      def send_notification(request_body)
        rest_hook_connection.post('', request_body)
      rescue Faraday::Error => e
        # Warning: This is a hack. If there is an error with the request such that we never get a response, we have
        #          no clean way to persist that information for the Inferno test to check later. The solution here
        #          is to persist the request anyway with a status of nil, using the error message as response body
        Faraday::Response.new(response_body: e.message, url: rest_hook_connection.url_prefix.to_s)
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
          result_id: @result_id,
          request_headers: inferno_request_headers,
          response_headers: inferno_response_headers,
          tags:
        )
      end
    end
  end
end
