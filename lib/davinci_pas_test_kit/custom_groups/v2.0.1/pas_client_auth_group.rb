require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientAuthGroup < Inferno::TestGroup
      id :pas_client_v201_auth
      title 'Review Authentication Interactions'
      description %(
        During these tests, Inferno will verify that the client interacted with Inferno's
        simulated authorization server in a conformant manner when requesting access tokens
        and that the client under test was able to use provided access tokens to make PAS
        requests.

        Before running these tests, perform at least one PAS workflow group so that the client
        will request an access token and use it on a PAS request.

        This group will be omitted if using dedicated endpoints for session authentication.
      )
      run_as_group

      group do
        id :pas_client_v201_auth_udap
        title 'Verify UDAP Authentication'

        test from: :udap_client_token_request_verification
        test from: :udap_client_token_use_verification,
             config: {
               options: { access_request_tags: [SUBMIT_TAG, INQUIRE_TAG] }
             }
      end

      group do
        id :pas_client_v201_auth_smart
        title 'Verify SMART Authentication'

        test from: :smart_client_token_request_verification,
             config: {
               inputs: {
                 smart_jwk_set: { optional: true }
               }
             }

        test from: :smart_client_token_use_verification,
             config: {
               options: { access_request_tags: [SUBMIT_TAG, INQUIRE_TAG] },
               inputs: { smart_jwk_set: { optional: true } }
             }
      end
    end
  end
end
