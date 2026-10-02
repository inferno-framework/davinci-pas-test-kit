module DaVinciPASTestKit
  class AbstractRegistrationConfigurationSMARTDisplay < Inferno::Test
    id :pas_client_reg_config_smart_display
    title 'PAS client registers Inferno as a PAS server'
    description %(
      During this test, Inferno will wait while the tester configures the client
      system to communicate with Inferno's simulated PAS server using
      endpoints authenticated using SMART Backend Services. The "User Action Required"
      dialog that appears during the test will provide all the information needed
      for testers to configure the client system, including the FHIR base URL, the
      token endpoint, and the system's assigned client id.
    )
    attestation

    input :client_id
    output :confirmation_url

    run do
      identifier = client_id
      confirmation_url = "#{resume_pass_url}?token=#{identifier}"
      output(confirmation_url:)

      wait(
        identifier:,
        message: %(
          **Inferno Simulated Server Details**:

          FHIR Base URL: `#{fhir_base_url}`

          Authentication Details:
          - SMART Client Id: `#{client_id}`
          - Token endpoint: `#{token_url}`

          [Click here](#{confirmation_url}) once you have configured
          the client to authenticate with Inferno and send PAS requests
          to Inferno at the above endpoint.
        )
      )
    end
  end
end
