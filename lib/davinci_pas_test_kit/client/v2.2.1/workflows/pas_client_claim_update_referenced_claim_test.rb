require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-65
    class PASClientClaimUpdateReferencedClaimTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_referenced_claim_test
      title 'Claim Update references and includes the Claim being updated'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-65)
        that the Claim being updated is referenced in the `Claim.related.claim` element and included in the
        Bundle. This test checks each Claim Update made during this group and confirms that it references a
        prior Claim and that the referenced Claim is present in the Bundle.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-65'

      run do
        steps = received_claim_update_steps(claim_update_updates)
        skip_if steps.empty?, 'No Claim Update requests were received to verify.'

        steps.each do |step|
          references = related_claim_references(step[:claim])
          if references.blank?
            add_message('error',
                        "The #{step[:label]} Claim must reference the Claim being updated in Claim.related.claim.")
            next
          end

          references.each do |reference|
            referenced_entry = bundle_entry_for_reference(step[:bundle], reference)
            next if referenced_entry&.resource.is_a?(FHIR::Claim)

            add_message('error',
                        "The Claim referenced in Claim.related.claim (#{reference}) of the #{step[:label]} " \
                        'must be included in the Bundle.')
          end
        end

        assert_no_error_messages('One or more Claim Updates did not reference and include the Claim being ' \
                                 'updated. See Messages for details.')
      end
    end
  end
end
