require 'udap_security_test_kit'
require_relative 'client_auth/token_udap_verification_test'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientAuthUDAPGroup < Inferno::TestGroup
      id :pas_client_v201_auth_udap
      title 'Review UDAP Authentication Interactions'
      description %(
        During these tests, Inferno will verify that the client interacted with Inferno's
        simulated UDAP authorization server in a conformant manner when requesting access tokens
        and that the client under test was able to use provided access tokens to make PAS
        requests.

        Before running these tests, perform at least one PAS workflow group so that the client
        will request an access token and use it on a PAS request.

      )
      run_as_group

      test from: :pas_client_v201_token_udap_verification
      test from: :udap_client_token_use_verification,
           config: {
             options: { access_request_tags: [SUBMIT_TAG, INQUIRE_TAG] }
           }
    end
  end
end
