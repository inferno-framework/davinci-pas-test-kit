# frozen_string_literal: true

module DaVinciPASTestKit
  # Where the claim and Subscription endpoints look for the session identifier, either the session
  # path or the client id embedded in the bearer token. Used in responses when no session is found.
  SESSION_PATH_OR_BEARER_TOKEN_LOCATION_DESCRIPTION =
    'the path or embedded within the bearer token in the Authorization header'
end
