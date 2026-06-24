require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-71 and spec-72
    class PASClientClaimUpdateChangedEntriesTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_changed_entries_test
      title 'Added, modified, or canceled entries carry an infoChanged extension with the correct valueCode'
      description %(
        The PAS IG requires that entries added, modified, or canceled compared to the immediately prior version
        of the Claim referenced in `Claim.related.claim`
        [contain an infoChanged extension](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-71)
        within the `Claim.item` or `Claim.supportingInfo` element, and that the
        [infoChanged valueCode](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-72)
        distinguishes added entries from modified or canceled entries.

        The bound [PAS Information Change Mode value set](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/ValueSet-PASInformationChangeMode.html)
        defines exactly two codes: `added` ("new information that was not sent previously") and `changed`
        ("previously sent information has been changed"). This test compares each detail-bearing Claim Update
        against the immediately prior Claim, classifies each entry as added/modified/canceled (comparing content
        while ignoring the change-tracking extensions), and confirms that each changed entry carries an
        infoChanged extension whose valueCode is valid and matches its change type - `added` for newly added
        entries and `changed` for modified or canceled entries.

        **Note:** the spec-72 conformance text states added entries use `changed`, which conflicts with the
        value set's definition of `added`; this test follows the value set definitions.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-71', 'hl7.fhir.us.davinci-pas_2.2.1@spec-72'

      run do
        comparisons = claim_update_detail_comparisons
        skip_if comparisons.empty?,
                'Not enough consecutive Claim Update requests were received to verify change marking.'

        comparisons.each do |comparison|
          check_changed_entries_marked(comparison[:current].item, comparison[:prior].item, 'item', comparison)
          check_changed_entries_marked(comparison[:current].supportingInfo, comparison[:prior].supportingInfo,
                                       'supportingInfo', comparison)
        end

        assert_no_error_messages('One or more changed entries were missing an infoChanged extension or used an ' \
                                 'incorrect valueCode. See Messages for details.')
      end

      def check_changed_entries_marked(current_entries, prior_entries, kind, comparison)
        prior_by_sequence = index_by_sequence(prior_entries)

        Array(current_entries).each do |entry|
          prior_entry = prior_by_sequence[entry.sequence]
          change_type =
            if prior_entry.nil?
              'added'
            elsif newly_cancelled?(entry, prior_entry)
              'canceled'
            elsif entry_modified?(entry, prior_entry)
              'modified'
            end
          next if change_type.nil?

          extension = info_changed_extension(entry)
          if extension.nil?
            add_message('error',
                        "The #{change_type} #{kind} (sequence #{entry.sequence}) in the " \
                        "#{comparison[:current_label]} must contain an infoChanged extension (it changed " \
                        "relative to the #{comparison[:prior_label]}).")
            next
          end

          check_info_changed_code(extension.valueCode, change_type, kind, entry, comparison)
        end
      end

      # Newly added entries SHALL use `added`; modified or canceled entries SHALL use `changed`.
      def check_info_changed_code(code, change_type, kind, entry, comparison)
        unless INFO_CHANGE_MODE_CODES.include?(code)
          add_message('error',
                      "The infoChanged extension on the #{kind} (sequence #{entry.sequence}) in the " \
                      "#{comparison[:current_label]} has valueCode '#{code}', which is not in the PAS Information " \
                      "Change Mode value set (allowed: #{INFO_CHANGE_MODE_CODES.join(', ')}).")
          return
        end

        expected_code = change_type == 'added' ? 'added' : 'changed'
        return if code == expected_code

        descriptor = change_type == 'added' ? 'newly added' : 'modified or canceled'
        add_message('error',
                    "The infoChanged extension on the #{kind} (sequence #{entry.sequence}) in the " \
                    "#{comparison[:current_label]} has valueCode '#{code}', but an entry that was #{descriptor} " \
                    "relative to the #{comparison[:prior_label]} SHALL use valueCode '#{expected_code}' per the " \
                    'value set definitions.')
      end
    end
  end
end
