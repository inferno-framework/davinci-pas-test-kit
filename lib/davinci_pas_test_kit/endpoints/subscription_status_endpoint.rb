require_relative '../tags'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class SubscriptionStatusEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils
    include ResponseGenerator

    def test_run_identifier
      request.headers['authorization']&.delete_prefix('Bearer ')
    end

    def make_response
      response.format = :json
      subscription = find_subscription(test_run.test_session_id)

      unless subscription.present?
        not_found
        return
      end

      subscription_id = request.params[:id]

      # Handle resource-level status params
      unless subscription_id.present?
        begin
          params = FHIR.from_contents(request.body.string)
        rescue StandardError
          response.status = 400
          response.body = operation_outcome('error', 'invalid', 'Invalid Parameters in request body').to_json
          return
        end

        unless subscription_params_match?(params, subscription)
          not_found
          return
        end
      end

      subscription_url = "#{base_subscription_url}/#{subscription.id}"
      subscription_topic = subscription.criteria
      status_code = determine_subscription_status_code(subscription_id)
      event_count = determine_event_count(test_run.test_session_id)

      notification_json = notification_bundle_input(result)
      if notification_json.blank?
        notification_timestamp = Time.now.utc
        mock_status_bundle = FHIR::Bundle.new(
          id: SecureRandom.uuid,
          timestamp: notification_timestamp.iso8601,
          type: 'history'
        )
        mock_notification_status = build_mock_notification_status(notification_timestamp, subscription_url,
                                                                  subscription_topic, nil, nil)
        mock_status_bundle.entry << build_mock_notification_status_entry(mock_notification_status, subscription_url)
        notification_json = mock_status_bundle.to_json
      end
      response.body = derive_status_bundle(notification_json, subscription_url, subscription_topic, status_code,
                                           event_count, request.url).to_json
      response.status = 200
    end

    def subscription_params_match?(params, subscription)
      id_params = find_params(params, 'id')

      return false if id_params&.any? && id_params&.none? { |p| p.valueString == subscription.id }

      status_params = find_params(params, 'status')
      subscription_status = determine_subscription_status_code(subscription.id)
      status_params.blank? || status_params.any? { |p| p.valueString == subscription_status }
    end

    def tags
      [SUBSCRIPTION_STATUS_TAG]
    end

    def not_found
      response.status = 404
      response.body = operation_outcome('error', 'not-found').to_json
    end

    def find_params(params, name)
      params&.parameter&.filter { |p| p.name == name }
    end

    def base_subscription_url
      request.url.sub(/(#{Regexp.escape(FHIR_SUBSCRIPTION_PATH)}).*/, '\1')
    end
  end
end
