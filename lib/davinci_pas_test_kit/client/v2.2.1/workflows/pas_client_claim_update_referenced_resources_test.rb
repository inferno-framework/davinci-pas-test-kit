require_relative 'pas_client_claim_update_validation_utils'
require_relative '../../../cross_suite/pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-67 - reuses the existing PasBundleValidation reference-presence logic.
    class PASClientClaimUpdateReferencedResourcesTest < Inferno::Test
      include ClaimUpdateValidationUtils
      include DaVinciPASTestKit::PasBundleValidation

      id :pas_client_v221_claim_update_referenced_resources_test
      title 'Request Bundles updating a Claim include all resources referenced by the updated Claim'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-67)
        that all other referenced resources are included in the Bundle. This test checks each Claim Update made
        during this group and confirms every resource referenced by the Claim is present in the Bundle exactly
        once.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-67'

      run do
        steps = received_claim_update_steps
        skip_if steps.empty?, 'No Claim Update requests were received to verify.'

        steps.each do |step|
          bundle = step[:bundle]
          base_url = extract_base_url(bundle.entry.first&.fullUrl)
          # The reused reference-presence check verifies the primary Update Claim's parent reference and the
          # parent's own referenced resources, while skipping a non-primary Claim's `related` so the
          # deliberately-omitted grandparent (spec-65/66) is not flagged as missing.
          validation_error_messages.clear
          check_presence_of_referenced_resources(step[:claim], base_url, bundle.entry)
          validation_error_messages.each do |message|
            add_message('error', "In the #{step[:label]} request: #{message}")
          end
        end

        assert_no_error_messages('Not all resources referenced by a Claim Update are included in the Bundle ' \
                                 'exactly once. See Messages for details.')
      end
    end
  end
end
