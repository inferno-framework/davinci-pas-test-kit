require 'smart_app_launch_test_kit'
require_relative 'pas_client_options'
require_relative '../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientAuthSMARTGroup < Inferno::TestGroup
      id :pas_client_v201_auth_smart
      title 'Review Authentication Interactions'
      description %(
        During these tests, Inferno will verify that the client interacted with Inferno's
        simulated SMART authorization server in a conformant manner when requesting access tokens
        and that the client under test was able to use provided access tokens to make PAS
        requests.

        Before running these tests, execute the tests for at least one "PAS workflows" sub-group
        so that the client will request an access token and use it on a PAS request.
      )
      run_as_group

      # smart auth verification
      test from: :smart_client_token_request_bsca_verification,
           config: {
             options: { endpoint_suite_id: :davinci_pas_client_suite_v201 }
           }
      test from: :smart_client_token_use_verification,
           config: {
             options: { access_request_tags: [SUBMIT_TAG, INQUIRE_TAG] }
           }
    end
  end
end
