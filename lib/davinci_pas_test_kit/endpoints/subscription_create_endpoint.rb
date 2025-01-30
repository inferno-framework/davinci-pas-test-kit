require_relative '../tags'
require_relative '../jobs/send_subscription_handshake'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class SubscriptionCreateEndpoint < Inferno::DSL::SuiteEndpoint
    include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::SubscriptionSimulationUtils

    def test_run_identifier
      request.headers['authorization']&.delete_prefix('Bearer ')
    end

    def make_response
      response.format = :json
      response.status = 400

      begin
        subscription = FHIR.from_contents(request.body.string)
      rescue StandardError
        response.body = operation_outcome('error', 'invalid', 'No recognized R4 Subscription in request body').to_json
        return
      end

      verification_outcome = verify_subscription(subscription)
      if verification_outcome.present?
        response.body = verification_outcome.to_json
        return
      end

      # Deny subscription if one already created
      requests = requests_repo.tagged_requests(test_run.test_session_id, tags)
      existing_subscription_request = requests.find { |r| r.status == 201 }
      if existing_subscription_request.present?
        subscription_hash = JSON.parse(existing_subscription_request.response_body)
        error_text = 'Inferno only supports one subscription per test run. Subscription already created with ' \
                     "ID #{subscription_hash['id']}"
        response.body = operation_outcome('error', 'business-rule', error_text).to_json
        return
      end

      # Form response
      notification_json = nil # no notification
      subscription_id = SecureRandom.uuid
      # We have to manipulate the raw hash so that we don't lose the _payload primitive extension
      subscription_hash = JSON.parse(request.body.string).merge('id' => subscription_id, 'status' => 'requested')
      subscription_hash['channel']['payload'] = actual_mime_type(subscription)
      response.status = 201
      response.body = subscription_hash.to_json

      # Kick off handshake job
      subscription_url = "#{request.url}/#{subscription_id}"
      client_endpoint = subscription.channel.endpoint
      bearer_token = client_access_token_input(result)
      test_suite_base_url = request.url.chomp('/').chomp(FHIR_SUBSCRIPTION_PATH)
      Inferno::Jobs.perform(Jobs::SendSubscriptionHandshake, test_run.id, test_run.test_session_id, result.id,
                            subscription_id, subscription_url, client_endpoint, bearer_token, notification_json,
                            test_run_identifier, test_suite_base_url)
    end

    def tags
      [SUBSCRIPTION_CREATE_TAG]
    end

    def verify_subscription(subscription)
      unless subscription.is_a? FHIR::Subscription
        return operation_outcome('error', 'invalid', 'No recognized R4 Subscription in request body')
      end

      unless subscription.channel&.type == 'rest-hook'
        return operation_outcome('error', 'business-rule', 'channel.type must be rest-hook')
      end

      unless valid_url?(subscription.channel&.endpoint)
        return operation_outcome('error', 'value', 'channel.endpoint is not recognized as a conformant URL')
      end

      heartbeat_period = find_heartbeat_period(subscription)
      operation_outcome('error', 'not-supported', 'heartbeatPeriod is not supported') unless heartbeat_period.nil?
    end

    def find_heartbeat_period(subscription)
      subscription&.channel&.extension&.find do |e|
        e.url == 'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-heartbeat-period'
      end
    end

    def valid_url?(url)
      uri = URI.parse(url)
      %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end
  end
end
