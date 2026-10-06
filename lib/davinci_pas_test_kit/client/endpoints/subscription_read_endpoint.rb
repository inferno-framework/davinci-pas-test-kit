require_relative '../../cross_suite/tags'
require 'subscriptions_test_kit'

module DaVinciPASTestKit
  class SubscriptionReadEndpoint < SubscriptionsTestKit::SubscriptionReadEndpoint
    error_response_format :operation_outcome

    def test_run_identifier_location_description
      'the path or embedded within the bearer token in the Authorization header'
    end

    def test_run_identifier
      return request.params[:session_path] if request.params[:session_path].present?

      UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
        request.headers['authorization']&.delete_prefix('Bearer ')
      )
    end

    def make_response
      if expired_token?
        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
        return
      end

      super
    end

    def tags
      # Requests rejected for an expired token are not treated as submissions of any workflow.
      return [] if expired_token?

      [SUBSCRIPTION_READ_TAG]
    end

    private

    # Memoized so the token is only decoded and parsed once per request, even though both
    # #tags and #make_response need to check it.
    def expired_token?
      return @expired_token if defined?(@expired_token)

      @expired_token = UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)
    end
  end
end
