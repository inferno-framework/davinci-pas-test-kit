require_relative 'pas_client_operation_failure_group'
require_relative 'pas_client_processing_error_group'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientErrorHandlingGroup < Inferno::TestGroup
      id :pas_client_v221_error_handling_group
      title 'Error Handling'
      description %(
        The error handling tests verify that the client can appropriately handle prior
        authorization error responses from the server, including both HTTP-level operation
        failures and business-level processing errors conveyed within a response bundle.

        These tests correspond to the requirements in IG §7.2.5 (Prior Authorization
        Transaction Error Handling).
      )

      group from: :pas_client_v221_operation_failure_group
      group from: :pas_client_v221_processing_error_group
    end
  end
end
