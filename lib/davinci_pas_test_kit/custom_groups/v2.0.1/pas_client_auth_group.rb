require_relative 'client_tests/pas_client_udap_token_request_test'
require_relative 'client_tests/pas_client_udap_token_use_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientAuthGroup < Inferno::TestGroup
      id :pas_client_v201_auth
      title 'Demonstrate Client Authentication'
      description %(
        Demonstrate the ability of the client to authenticate and to request and use
        access tokens provided by Inferno's simulated auth server.
      )
      run_as_group
      input :client_id,
            title: 'Client Id',
            type: 'text',
            optional: true,
            description: %(
        Client Id which the client under test is registered as with the Inferno simulated
        authentication server.
      )

      group do
        id :pas_client_v201_auth_udap
        title 'Verify UDAP Authentication'

        test from: :pas_client_v201_udap_token_request_test
        test from: :pas_client_v201_udap_token_use_test
      end

      group do
        id :pas_client_v201_auth_smart
        title 'Verify SMART Authentication'

        run do
          omit_if true, 'implement me!'
        end
      end

      # verify token requests
      # verify a provided token was used
    end
  end
end
