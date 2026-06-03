require_relative '../../registration/abstract_configuration_smart_display_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class RegistrationConfigurationSMARTDisplay < AbstractRegistrationConfigurationSMARTDisplay
      include URLs

      id :pas_client_v221_reg_config_smart_display
    end
  end
end
