require_relative 'client_tests/pas_client_token_request_test'
require_relative 'client_tests/pas_client_token_validation_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientAuthenticationGroup < Inferno::TestGroup
      id :pas_client_v201_authentication_group
      title 'Demonstrate Authorization'
      description %(
        This group of tests allows Inferno to act as a OAuth server
        and provide access tokens for the client under test to use
        when making further requests.

        The tests assume that the authentication workflow starts
        after client registration. Upon clicking the "Run Tests" button
        in the upper right, Inferno will ask for an input for the `client_id`
        that was used for client registration, or manually configured in the
        client.

        Before submitting a token request, click the "Submit" button at the
        bottom of the dialog to confirm the `client_id` that Inferno will
        watch for.

        Finally, make a valid token request that includes the specified `client_id`
        to indicated token endpoint. This should be a POST of an `x-www-form-encoded`
        body containing keys for `grant_type` with a value of `client_crendials` and
        `client_id` with a value of the configured `client_id` value. For example, if
        the `client_id` value was `123`, then the body of the request would be:

        ```grant_type=client_credentials&client_id=123```

        The response json object will include an `access_token` key, for example:

        ```{"access_token":"97e792038d922bc3cf388b608e45c318","token_type":"bearer","expires_in":300}```

        The value of the `access_token` key (`97e792038d922bc3cf388b608e45c318` in the example)
        must be sent with every subsequent request to Inferno during this session in
        the "Authorization" HTTP header with prefix "Bearer: ". In this example, the
        Authorization HTTP header would have value:

        ```Bearer: 97e792038d922bc3cf388b608e45c318```
      )
      run_as_group

      test from: :pas_client_v201_token_request_test
      test from: :pas_client_v201_token_validation_test
    end
  end
end
