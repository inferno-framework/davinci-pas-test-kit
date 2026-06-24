require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-68
    class PASClientClaimUpdateEntriesPreservedTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_entries_preserved_test
      title 'Claim Update preserves all prior item and supportingInfo entries'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-68)
        that when changing the details of the request, the Claim contains all item and supportingInfo entries
        from the original Claim and any previous update Claims, with `sequence` values preserved. This test
        compares each detail-bearing Claim Update against the immediately prior Claim and confirms that every
        prior item and supportingInfo sequence is still present.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-68'

      run do
        comparisons = claim_update_detail_comparisons
        skip_if comparisons.empty?,
                'Not enough consecutive Claim Update requests were received to verify entry preservation.'

        comparisons.each do |comparison|
          missing_items = entry_sequences(comparison[:prior].item) - entry_sequences(comparison[:current].item)
          unless missing_items.empty?
            add_message('error',
                        "The #{comparison[:current_label]} Claim must retain all item entries from the " \
                        "#{comparison[:prior_label]} Claim with their sequence values preserved. " \
                        "Missing item sequence(s): #{missing_items.join(', ')}.")
          end

          missing_supporting_info =
            entry_sequences(comparison[:prior].supportingInfo) - entry_sequences(comparison[:current].supportingInfo)
          next if missing_supporting_info.empty?

          add_message('error',
                      "The #{comparison[:current_label]} Claim must retain all supportingInfo entries from the " \
                      "#{comparison[:prior_label]} Claim with their sequence values preserved. " \
                      "Missing supportingInfo sequence(s): #{missing_supporting_info.join(', ')}.")
        end

        assert_no_error_messages('One or more Claim Updates did not preserve all prior item or supportingInfo ' \
                                 'entries.')
      end
    end
  end
end
