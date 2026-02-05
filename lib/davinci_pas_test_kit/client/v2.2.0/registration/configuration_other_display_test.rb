require_relative '../../registration/abstract_configuration_other_display_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV220
    class RegistrationConfigurationOtherDisplay < AbstractRegistrationConfigurationOtherDisplay
      include URLs

      id :pas_client_v220_reg_config_other_display
    end
  end
end
