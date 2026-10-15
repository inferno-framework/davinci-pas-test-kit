# frozen_string_literal: true

require 'udap_security_test_kit'

module DaVinciPASTestKit
  # Identifies the test session for the claim and Subscription endpoints, using either the session
  # path or the client id embedded in the bearer token.
  module EndpointSessionIdentification
    # Where the session identifier is expected. Used in responses when no session is found.
    LOCATION_DESCRIPTION = 'the path or embedded within the bearer token in the Authorization header'

    def test_run_identifier_location_description
      LOCATION_DESCRIPTION
    end

    def test_run_identifier
      return request.params[:session_path] if request.params[:session_path].present?

      UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
        request.headers['authorization']&.delete_prefix('Bearer ')
      )
    end
  end
end
