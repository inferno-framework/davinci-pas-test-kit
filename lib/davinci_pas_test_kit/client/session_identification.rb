require 'udap_security_test_kit'
require_relative 'pas_client_options'

module DaVinciPASTestKit
  module SessionIdentification
    # Wait identifiers:
    # - A wait during which the client sends requests to Inferno (including waits that also offer a
    #   "click here when done" link) must use session_wait_identifier, since Inferno's endpoints find
    #   the waiting test from the client id or session URL path on the request.
    # - A wait that only the tester (e.g., an attestation) or an Inferno job continues must use a fresh
    #   SecureRandom.uuid, so that a stale link from an earlier wait in the session can't resume it.
    def session_wait_identifier(client_id, session_url_path)
      # look at test config and determine the wait identifier to use
      # at somepoint this would be an inferno type, for now, just two options
      return client_id if client_id.present?
      return session_url_path if session_url_path.present?

      test_session_id
    end

    def session_endpoint_url(endpoint, client_id, session_url_path)
      path =
        if client_id.present?
          ''
        elsif session_url_path.present?
          session_url_path
        else
          test_session_id
        end

      case endpoint
      when :submit
        session_submit_url(path)
      when :inquire
        session_inquire_url(path)
      when :subscription
        session_fhir_subscription_url(path)
      end
    end

    def auth_description_for_wait(client_id)
      case suite_options[:client_type]
      when PASClientOptions::OTHER_AUTH
        'No authentication with Inferno is required. Requests will be associated ' \
        'with this session based on the endpoint alone.'
      when PASClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
        authenticated_auth_description_for_wait(client_id, 'SMART Backend Services')
      when PASClientOptions::UDAP_CLIENT_CREDENTIALS
        authenticated_auth_description_for_wait(client_id, 'UDAP B2B Client Credentials')
      end
    end

    def authenticated_auth_description_for_wait(client_id, type)
      "Requests must be authenticated by first obtaining a #{type} " \
        'access token using' \
        "\n\n- Token endpoint: `#{token_url}`" \
        "\n- Client Id: `#{client_id}`\n\n" \
        'Only requests that include an obtained access token as a bearer token ' \
        'in the Authorization header of the HTTP request will be recognized as ' \
        'associated with this session and return successful responses.'
    end
  end
end
