require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientRegistrationConfigurationOtherDisplay < Inferno::Test
      include URLs

      id :pas_client_v201_reg_config_other_display
      title 'Confirm client configuration'
      description %(
        This test provides all the information needed for testers to configure
        the client under test to communicate with Inferno's simulated PAS server
        using dedicated endpoints.
      )
      input :session_url_path,
            title: 'Session-specific URL path extension',
            type: 'text',
            optional: true,
            description: %(
              Inferno will use this value to setup dedicated session-specific FHIR endpoints
              to use during these tests. If not provided a value will be generated.
            )
      output :session_url_path

      run do
        if session_url_path.blank?
          new_session_url_path = test_session_id
          output(session_url_path: new_session_url_path)
        end
        wait_identifier = session_url_path || new_session_url_path

        wait(
          identifier: wait_identifier,
          message: %(
            **Inferno Simulated Server Details**:

            FHIR Base URL: `#{session_fhir_base_url(wait_identifier)}`

            [Click here](#{resume_pass_url}?token=#{wait_identifier}) once you have configured
            the client to connect to Inferno at the above endpoints.
          )
        )
      end
    end
  end
end
