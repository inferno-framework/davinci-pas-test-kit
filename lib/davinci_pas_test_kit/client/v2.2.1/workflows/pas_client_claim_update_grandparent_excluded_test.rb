require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-66
    class PASClientClaimUpdateGrandparentExcludedTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_grandparent_excluded_test
      title 'Claim Update referencing another update omits the grandparent Claim'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-66)
        that when the Claim being updated is itself a Claim Update, its referenced (grandparent) Claim is not
        included. This test checks each Claim Update whose referenced Claim is itself an update and confirms
        that the grandparent Claim is not included in the Bundle.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-66'

      run do
        applicable = received_claim_update_steps(claim_update_updates).filter_map do |step|
          parent_reference = related_claim_references(step[:claim]).first
          next if parent_reference.blank?

          parent_entry = bundle_entry_for_reference(step[:bundle], parent_reference)
          parent_claim = parent_entry&.resource
          next unless parent_claim.is_a?(FHIR::Claim)

          grandparent_reference = related_claim_references(parent_claim).first
          next if grandparent_reference.blank? # the referenced Claim is not itself an update

          step.merge(parent_reference:, grandparent_reference:)
        end

        skip_if applicable.empty?,
                'No Claim Update referencing another Claim Update was received, so this requirement was not checked.'

        applicable.each do |step|
          grandparent_entry = bundle_entry_for_reference(step[:bundle], step[:grandparent_reference])
          next if grandparent_entry.nil?

          add_message('error',
                      "In the #{step[:label]}, the included Claim (#{step[:parent_reference]}) is itself a Claim " \
                      "Update, so its referenced Claim (#{step[:grandparent_reference]}) SHALL NOT be included in " \
                      'the Bundle.')
        end

        assert_no_error_messages('One or more Claim Updates included the grandparent Claim that SHALL NOT be ' \
                                 'present. See Messages for details.')
      end
    end
  end
end
