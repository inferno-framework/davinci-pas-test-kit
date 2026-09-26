module DaVinciPASTestKit
  class AbstractRegistrationConfigurationOtherDisplay < Inferno::Test
    id :pas_client_reg_config_other_display
    title 'PAS client registers Inferno as a PAS server'
    description %(
      During this test, Inferno will wait while the tester configures the client
      system to communicate with Inferno's simulated PAS server using dedicated
      endpoints. The "User Action Required" dialog that appears during the test
      will provide all the information needed for testers to configure the client
      under test, including the FHIR base URL.
    )
    attestation

    input :session_url_path,
          title: 'Session-specific URL path extension',
          type: 'text',
          optional: true,
          description: %(
            Inferno will use this value to setup dedicated session-specific FHIR endpoints
            to use during these tests. If not provided a value will be generated.
          )
    output :session_url_path
    output :confirmation_url

    run do
      if session_url_path.blank?
        new_session_url_path = test_session_id
        output(session_url_path: new_session_url_path)
      end
      wait_identifier = session_url_path || new_session_url_path
      confirmation_url = "#{resume_pass_url}?token=#{wait_identifier}"
      output(confirmation_url:)

      wait(
        identifier: wait_identifier,
        message: %(
          **Inferno Simulated Server Details**:

          FHIR Base URL: `#{session_fhir_base_url(wait_identifier)}`

          [Click here](#{confirmation_url}) once you have configured
          the client to send PAS requests to Inferno at the above endpoint.
        )
      )
    end
  end
end
