# frozen_string_literal: true

require 'udap_security_test_kit'

module DaVinciPASTestKit
  # Checks whether the request's bearer token has expired.
  module ExpiredToken
    private

    # Memoized so the token is only decoded and parsed once per request, even though both
    # #tags and the response handling need to check it.
    def expired_token?
      return @expired_token if defined?(@expired_token)

      @expired_token = UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)
    end
  end

  # Prepended to endpoints that reject requests made with an expired bearer token before any other
  # handling.
  module ExpiredTokenRejection
    include ExpiredToken

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

      super
    end
  end
end
