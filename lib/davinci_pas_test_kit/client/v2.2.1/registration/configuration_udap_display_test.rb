require_relative '../../registration/abstract_configuration_udap_display_test'
require_relative '../urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    class RegistrationConfigurationUDAPDisplay < AbstractRegistrationConfigurationUDAPDisplay
      include URLs

      id :pas_client_v221_reg_config_udap_display
    end
  end
end
