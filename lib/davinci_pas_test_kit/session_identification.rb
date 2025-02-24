require_relative 'endpoints/mock_udap_server'

module DaVinciPASTestKit
  module SessionIdentification
    def inputs_to_wait_identifier(client_id, session_url_path)
      # look at test config and determine the wait identifier to use
      # at somepoint this would be an inferno type, for now, just two options
      return client_id if client_id.present?

      session_url_path
    end

    def inputs_to_session_endpont(endpoint, client_id, session_url_path)
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
      end
    end

    # interpret the bearer token structure to determine the wait identifer
    # - if structured like a token returned by the simulated Auth server, return the client URI
    # - otherwise, use the raw token (provided token)
    def bearer_token_to_wait_identifier(token)
      client_id = MockUdapServer.token_to_client_id(token)
      return client_id if client_id.present?

      token
    end
  end
end
