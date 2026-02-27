module DaVinciPASTestKit
  class AbstractRegistrationOtherAuthAttest < Inferno::Test
    id :pas_client_reg_other_auth_attest
    title 'Verify that the client supports an approach for authenticating itself to the server (Attestation)'
    description %(
      Since a standard auth approach was not chosen for this session, this test provides testers with an
      opportunity to attest to their client's ability to authenticate itself to a server
      using a method that this Inferno test suite does not support, such as mutual authentication
      TLS.
    )

    output :attest_true_url
    output :attest_false_url

    run do
      identifier = test_session_id
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      output(attest_true_url:)
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_false_url:)

      wait(
        identifier:,
        message: %(
          **Other Authentication Attestation**:

          I attest that the client system can authenticate itself with a PAS server using
          a mechanism other than the SMART Backend Services or UDAP B2B client credentials
          flows.

          [Click here](#{attest_true_url}) if the above statement is true.

          [Click here](#{attest_false_url}) if the above statement is false.
        )
      )
    end
  end
end
