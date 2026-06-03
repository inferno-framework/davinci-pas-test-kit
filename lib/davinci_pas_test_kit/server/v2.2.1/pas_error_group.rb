require_relative 'error_tests/pas_submission_error_test'
require_relative 'error_tests/pas_inquiry_error_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASErrorGroup < Inferno::TestGroup
      title 'Demonstrate Error Handling'
      description %(
        Validates Prior Authorization transaction error handling for malformed
        request bundles.
      )

      id :pas_v221_error_group
      run_as_group

      test from: :pas_server_v221_prior_auth_submission_error
      test from: :pas_server_v221_prior_auth_inquiry_error
    end
  end
end
