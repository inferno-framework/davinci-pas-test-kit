require_relative '../../registration/abstract_configuration_smart_display_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV220
    class RegistrationConfigurationSMARTDisplay < AbstractRegistrationConfigurationSMARTDisplay
      include URLs

      id :pas_client_v220_reg_config_smart_display
    end
  end
end
