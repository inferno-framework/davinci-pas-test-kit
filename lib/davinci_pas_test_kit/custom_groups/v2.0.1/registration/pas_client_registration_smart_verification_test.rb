require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../../endpoints/mock_udap_smart_server'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientRegistrationSMARTVerification < Inferno::Test
      include URLs

      id :pas_client_v201_reg_smart_verification
      title 'Verify SMART Registration'
      description %(
        During this test, Inferno will verify that the SMART registration details
        provided are conformant.
      )
      input :smart_jwk_set,
            optional: true
      input :client_id,
            optional: true

      output :client_id

      run do
        omit_if smart_jwk_set.blank?, 'Not configured for SMART authentication.'

        if client_id.blank?
          client_id = test_session_id
          output(client_id:)
        end

        jwks_warnings = []
        parsed_smart_jwk_set = MockUdapSmartServer.jwk_set(smart_jwk_set, jwks_warnings)
        jwks_warnings.each { |warning| add_message('warning', warning) }

        assert parsed_smart_jwk_set.length.positive?, 'JWKS content does not include any valid keys.'

        # TODO: add key-specific verification per end of https://build.fhir.org/ig/HL7/smart-app-launch/client-confidential-asymmetric.html#registering-a-client-communicating-public-keys

        assert messages.none? { |msg| msg[:type] == 'error' }, 'Invalid key set provided. See messages for details'
      end
    end
  end
end
