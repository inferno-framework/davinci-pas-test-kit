require_relative 'error_tests/pas_submission_error_test'
require_relative 'error_tests/pas_inquiry_error_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASErrorGroup < Inferno::TestGroup
      title 'Demonstrate Error Handling'
      description %(
        Validates Prior Authorization transaction error handling for malformed
        request bundles.
      )

      id :pas_v201_error_group
      run_as_group

      test from: :prior_auth_submission_error
      test from: :prior_auth_inquiry_error
    end
  end
end
