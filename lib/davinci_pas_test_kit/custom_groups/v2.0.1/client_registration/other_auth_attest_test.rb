require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientRegistrationOtherAuthAttest < Inferno::Test
      include URLs

      id :pas_client_v201_reg_other_auth_attest
      title 'Verify that the client supports an approach for authenticating itself to the server (Attestation)'
      description %(
        Since a standard auth approach was not chosen for this session, this test provides testers with an
        opportunity to attest to their client's ability to authenticate itself to a server
        using a method that this Inferno test suite does not support, such as mutual authentication
        TLS.
      )

      run do
        identifier = SecureRandom.hex(32)
        wait(
          identifier:,
          message: %(
            **Other Authentication Attestation**:

            I attest that the client system can authenticate itself with a PAS server using
            a mechanism other than the SMART Backend Services or UDAP B2B client credentials
            flows.

            [Click here](#{resume_pass_url}?token=#{identifier}) if the above statement is true.

            [Click here](#{resume_fail_url}?token=#{identifier}) if the above statement is false.
          )
        )
      end
    end
  end
end
