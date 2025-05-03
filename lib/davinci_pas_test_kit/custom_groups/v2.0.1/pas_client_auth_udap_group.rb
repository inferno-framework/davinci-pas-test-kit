require 'udap_security_test_kit'
require_relative '../../client_suite'
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

        Before running these tests, execute the tests for at least one "PAS workflows" sub-group
        so that the client will request an access token and use it on a PAS request.
      )
      run_as_group

      test from: :udap_client_token_request_cc_verification,
           config: {
             options: { endpoint_suite_id: :davinci_pas_client_suite_v201 }
           }
      test from: :udap_client_token_use_verification,
           config: {
             options: { access_request_tags: [SUBMIT_TAG, INQUIRE_TAG] }
           }
    end
  end
end
