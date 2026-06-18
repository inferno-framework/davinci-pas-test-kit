require_relative '../../../cross_suite/tags'
require_relative '../../../cross_suite/pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Shared helpers for the Claim Update verification tests. These tests reload the
    # requests received during the Claim Update wait tests (by their unique tags) and
    # inspect the submitted PAS Claim Update Bundles against the relevant conformance
    # requirements. No live state is used - everything is reloaded from the tagged,
    # persisted requests.
    module ClaimUpdateValidationUtils
      CERTIFICATION_TYPE_EXTENSION_URL =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-certificationType'.freeze
      INFO_CHANGED_EXTENSION_URL =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged'.freeze
      INFO_CANCELLED_EXTENSION_URL =
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/modifierextension-infoCancelled'.freeze
      CERTIFICATION_TYPE_CANCEL_CODE = '3'.freeze
      # The PAS Information Change Mode value set (CodeSystem PASTempCodes) defines exactly
      # these two codes: 'added' (new information) and 'changed' (previously sent info changed).
      INFO_CHANGE_MODE_CODES = %w[added changed].freeze

      # The ordered Claim Update submissions, paired with the unique tag each was stored under.
      def claim_update_steps
        [
          { label: 'initial submission', tag: CLAIM_UPDATE_INITIAL_TAG },
          { label: 'add-item update', tag: CLAIM_UPDATE_ADD_ITEM_TAG },
          { label: 'modify-and-cancel update', tag: CLAIM_UPDATE_MODIFY_CANCEL_TAG },
          { label: 'cancel-entire-request update', tag: CLAIM_UPDATE_CANCEL_ALL_TAG }
        ]
      end

      # The submissions that are updates to a previously submitted Claim (everything except
      # the initial submission).
      def claim_update_updates
        claim_update_steps.drop(1)
      end

      # The submissions that carry item/supportingInfo detail and can be compared against the
      # immediately prior version. The cancel-entire-request update is excluded because it needs
      # no items.
      def claim_update_detail_chain
        claim_update_steps.take(3)
      end

      # Reloads the most recent request stored under `tag` and parses it as a FHIR::Bundle.
      # Returns nil if no such request was received or it does not parse to a Bundle.
      def claim_update_bundle(tag)
        request = load_tagged_requests(tag).last
        return nil if request.nil? || request.request_body.blank?

        resource = FHIR.from_contents(request.request_body)
        resource.is_a?(FHIR::Bundle) ? resource : nil
      rescue StandardError
        nil
      end

      # The Claim being submitted is the first Claim entry in a PAS Request Bundle.
      def first_claim(bundle)
        return nil if bundle.nil?

        bundle.entry.map(&:resource).find { |resource| resource.is_a?(FHIR::Claim) }
      end

      # Builds ordered prior/current Claim comparisons across the detail chain, skipping any
      # link where a request was not received.
      def claim_update_detail_comparisons
        claims = claim_update_detail_chain.map do |step|
          bundle = claim_update_bundle(step[:tag])
          { label: step[:label], claim: bundle && first_claim(bundle) }
        end

        claims.each_cons(2).filter_map do |prior, current|
          next if prior[:claim].nil? || current[:claim].nil?

          { prior: prior[:claim], current: current[:claim],
            prior_label: prior[:label], current_label: current[:label] }
        end
      end

      # Finds the bundle entry that a reference points to, accommodating absolute fullUrls,
      # urn:uuid fullUrls, and relative "ResourceType/id" references.
      def bundle_entry_for_reference(bundle, reference)
        return nil if bundle.nil? || reference.blank?

        bundle.entry.find do |entry|
          next false if entry.nil?

          resource = entry.resource
          full_url = entry.fullUrl.to_s
          full_url == reference ||
            (resource && "#{resource.resourceType}/#{resource.id}" == reference) ||
            (full_url.present? && full_url.end_with?("/#{reference}"))
        end
      end

      def related_claim_references(claim)
        Array(claim&.related).filter_map { |related| related.claim&.reference }
      end

      # Returns a copy of the Claim with its `related` element removed, so reference-presence
      # checks do not traverse the Claim.related.claim chain (handled separately by spec-65/66).
      def claim_without_related(claim)
        return claim if claim.nil? || claim.related.blank?

        FHIR::Claim.new(claim.to_hash.tap { |hash| hash.delete('related') })
      end

      def entry_sequences(entries)
        Array(entries).map(&:sequence).compact
      end

      def index_by_sequence(entries)
        Array(entries).each_with_object({}) { |entry, map| map[entry.sequence] = entry }
      end

      def entry_kind(entry)
        entry.class.name.to_s.split('::').last == 'Item' ? 'item' : 'supportingInfo'
      end

      # A canceled item carries a certificationType extension with code 3 (Cancel).
      def certification_type_cancel?(element)
        Array(element&.extension).any? do |extension|
          extension.url == CERTIFICATION_TYPE_EXTENSION_URL &&
            Array(extension.valueCodeableConcept&.coding).any? do |coding|
              coding.code == CERTIFICATION_TYPE_CANCEL_CODE
            end
        end
      end

      def info_cancelled_extension(element)
        Array(element&.modifierExtension).find { |extension| extension.url == INFO_CANCELLED_EXTENSION_URL }
      end

      def info_cancelled?(element)
        info_cancelled_extension(element)&.valueBoolean == true
      end

      def info_changed_extension(element)
        Array(element&.extension).find { |extension| extension.url == INFO_CHANGED_EXTENSION_URL }
      end

      # An entry is treated as "canceled" when it carries either change marker.
      def cancellation_marked?(element)
        certification_type_cancel?(element) || info_cancelled_extension(element).present?
      end

      def newly_cancelled?(current_entry, prior_entry)
        info_cancelled?(current_entry) && !info_cancelled?(prior_entry)
      end

      # Compares an entry against its prior version, ignoring the change-tracking extensions
      # (infoChanged, certificationType) and modifier extension (infoCancelled), to determine
      # whether its substantive content was modified.
      def entry_modified?(current_entry, prior_entry)
        normalized_entry_hash(current_entry) != normalized_entry_hash(prior_entry)
      end

      def normalized_entry_hash(entry)
        hash = entry.to_hash
        if hash['extension'].is_a?(Array)
          hash['extension'] = hash['extension'].reject do |extension|
            [INFO_CHANGED_EXTENSION_URL, CERTIFICATION_TYPE_EXTENSION_URL].include?(extension['url'])
          end
          hash.delete('extension') if hash['extension'].empty?
        end
        if hash['modifierExtension'].is_a?(Array)
          hash['modifierExtension'] = hash['modifierExtension'].reject do |extension|
            extension['url'] == INFO_CANCELLED_EXTENSION_URL
          end
          hash.delete('modifierExtension') if hash['modifierExtension'].empty?
        end
        hash
      end

      # Collects the Claim Update steps for which a request was actually received, attaching the
      # parsed Bundle and Claim. Used by tests that inspect each submission independently.
      def received_claim_update_steps(steps = claim_update_steps)
        steps.filter_map do |step|
          bundle = claim_update_bundle(step[:tag])
          claim = first_claim(bundle)
          next if claim.nil?

          step.merge(bundle:, claim:)
        end
      end
    end

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
          assert references.present?,
                 "The #{step[:label]} Claim must reference the Claim being updated in Claim.related.claim."

          references.each do |reference|
            referenced_entry = bundle_entry_for_reference(step[:bundle], reference)
            assert referenced_entry&.resource.is_a?(FHIR::Claim),
                   "The Claim referenced in Claim.related.claim (#{reference}) of the #{step[:label]} " \
                   'must be included in the Bundle.'
          end
        end
      end
    end

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
                'No Claim Update referencing another Claim Update was received, so this requirement does not apply.'

        applicable.each do |step|
          grandparent_entry = bundle_entry_for_reference(step[:bundle], step[:grandparent_reference])
          assert grandparent_entry.nil?,
                 "In the #{step[:label]}, the included Claim (#{step[:parent_reference]}) is itself a Claim " \
                 "Update, so its referenced Claim (#{step[:grandparent_reference]}) SHALL NOT be included in " \
                 'the Bundle.'
        end
      end
    end

    # spec-67 - reuses the existing PasBundleValidation reference-presence logic.
    class PASClientClaimUpdateReferencedResourcesTest < Inferno::Test
      include ClaimUpdateValidationUtils
      include DaVinciPASTestKit::PasBundleValidation

      id :pas_client_v221_claim_update_referenced_resources_test
      title 'All resources referenced by a Claim Update are included in the Bundle'
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
          validation_error_messages.clear
          # The presence of the Claim being updated (Claim.related.claim) is governed by spec-65/66,
          # which also require that an updated Claim's own referenced Claim be omitted. Excluding
          # `related` here scopes the reused reference-presence check to the "other" referenced
          # resources and avoids recursing into the deliberately-omitted grandparent Claim.
          check_presence_of_referenced_resources(claim_without_related(step[:claim]), base_url, bundle.entry)
          assert validation_error_messages.blank?,
                 "In the #{step[:label]} request, not all resources referenced by the Claim are included " \
                 "in the Bundle exactly once:#{validation_error_messages.join(' ')}"
        end
      end
    end

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
          assert missing_items.empty?,
                 "The #{comparison[:current_label]} Claim must retain all item entries from the " \
                 "#{comparison[:prior_label]} Claim with their sequence values preserved. " \
                 "Missing item sequence(s): #{missing_items.join(', ')}."

          missing_supporting_info =
            entry_sequences(comparison[:prior].supportingInfo) - entry_sequences(comparison[:current].supportingInfo)
          assert missing_supporting_info.empty?,
                 "The #{comparison[:current_label]} Claim must retain all supportingInfo entries from the " \
                 "#{comparison[:prior_label]} Claim with their sequence values preserved. " \
                 "Missing supportingInfo sequence(s): #{missing_supporting_info.join(', ')}."
        end
      end
    end

    # spec-69
    class PASClientClaimUpdateCancelledEntriesTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_cancelled_entries_test
      title 'Canceled entries carry the infoCancelled modifier extension'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-69)
        that item and supportingInfo entries removed from the request include the infoCancelled modifier
        extension with a valueBoolean of `true`. This test checks each Claim Update for entries marked as
        canceled and confirms the infoCancelled modifier extension is present and `true`.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-69'

      run do
        steps = received_claim_update_steps
        skip_if steps.empty?, 'No Claim Update requests were received to verify.'

        cancelled_entries = steps.flat_map do |step|
          (Array(step[:claim].item) + Array(step[:claim].supportingInfo))
            .select { |entry| cancellation_marked?(entry) }
            .map { |entry| { step:, entry: } }
        end

        skip_if cancelled_entries.empty?,
                'No canceled item or supportingInfo entries were received to verify (the modify-and-cancel ' \
                'update is expected to cancel an item).'

        cancelled_entries.each do |cancelled|
          entry = cancelled[:entry]
          assert info_cancelled?(entry),
                 "A canceled #{entry_kind(entry)} (sequence #{entry.sequence}) in the #{cancelled[:step][:label]} " \
                 'must include the infoCancelled modifier extension with a valueBoolean of true.'
        end
      end
    end

    # spec-70
    class PASClientClaimUpdateCancelledItemsCertificationTypeTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_cancelled_items_certtype_test
      title 'Canceled items carry a certificationType extension with code 3'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-70)
        that canceled items additionally contain a certificationType extension with a code of 3 (Cancel) in the
        `Claim.item.extension` element. This test checks each Claim Update for canceled items and confirms the
        certificationType Cancel extension is present.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-70'

      run do
        steps = received_claim_update_steps
        skip_if steps.empty?, 'No Claim Update requests were received to verify.'

        cancelled_items = steps.flat_map do |step|
          Array(step[:claim].item)
            .select { |item| cancellation_marked?(item) }
            .map { |item| { step:, item: } }
        end

        skip_if cancelled_items.empty?,
                'No canceled items were received to verify (the modify-and-cancel update is expected to ' \
                'cancel an item).'

        cancelled_items.each do |cancelled|
          item = cancelled[:item]
          assert certification_type_cancel?(item),
                 "A canceled item (sequence #{item.sequence}) in the #{cancelled[:step][:label]} must contain " \
                 'a certificationType extension with a code of 3 (Cancel) in Claim.item.extension.'
        end
      end
    end

    # spec-71
    class PASClientClaimUpdateChangedEntriesTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_changed_entries_test
      title 'Added, modified, or canceled entries carry an infoChanged extension'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-71)
        that entries added, modified, or canceled compared to the immediately prior version of the Claim
        referenced in `Claim.related.claim` contain an infoChanged extension within the `Claim.item` or
        `Claim.supportingInfo` element. This test compares each detail-bearing Claim Update against the
        immediately prior Claim, classifies each entry as added/modified/canceled (comparing content while
        ignoring the change-tracking extensions), and confirms changed entries are marked.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-71'

      run do
        comparisons = claim_update_detail_comparisons
        skip_if comparisons.empty?,
                'Not enough consecutive Claim Update requests were received to verify change marking.'

        comparisons.each do |comparison|
          assert_changed_entries_marked(comparison[:current].item, comparison[:prior].item, 'item', comparison)
          assert_changed_entries_marked(comparison[:current].supportingInfo, comparison[:prior].supportingInfo,
                                        'supportingInfo', comparison)
        end
      end

      def assert_changed_entries_marked(current_entries, prior_entries, kind, comparison)
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

          assert info_changed_extension(entry).present?,
                 "The #{change_type} #{kind} (sequence #{entry.sequence}) in the #{comparison[:current_label]} " \
                 "must contain an infoChanged extension (it changed relative to the #{comparison[:prior_label]})."
        end
      end
    end

    # spec-72
    class PASClientClaimUpdateInfoChangedCodeTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_info_changed_code_test
      title 'infoChanged extensions use the correct valueCode'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-72)
        that the infoChanged extension valueCode distinguishes added entries from modified or canceled entries.

        The bound [PAS Information Change Mode value set](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/ValueSet-PASInformationChangeMode.html)
        defines exactly two codes: `added` ("new information that was not sent previously") and `changed`
        ("previously sent information has been changed"). This test confirms every infoChanged extension uses a
        valid code and that newly added entries use `added` while modified or canceled entries use `changed`,
        following the value set's normative definitions.

        **Note:** the spec-72 conformance text states added entries use `changed`, which conflicts with the
        value set's definition of `added`; this test follows the value set definitions.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-72'

      run do
        comparisons = claim_update_detail_comparisons
        skip_if comparisons.empty?,
                'Not enough consecutive Claim Update requests were received to verify infoChanged valueCodes.'

        comparisons.each do |comparison|
          assert_info_changed_codes(comparison[:current].item, comparison[:prior].item, 'item', comparison)
          assert_info_changed_codes(comparison[:current].supportingInfo, comparison[:prior].supportingInfo,
                                    'supportingInfo', comparison)
        end
      end

      def assert_info_changed_codes(current_entries, prior_entries, kind, comparison)
        prior_by_sequence = index_by_sequence(prior_entries)

        Array(current_entries).each do |entry|
          extension = info_changed_extension(entry)
          next if extension.nil?

          code = extension.valueCode
          assert INFO_CHANGE_MODE_CODES.include?(code),
                 "The infoChanged extension on the #{kind} (sequence #{entry.sequence}) in the " \
                 "#{comparison[:current_label]} has valueCode '#{code}', which is not in the PAS Information " \
                 "Change Mode value set (allowed: #{INFO_CHANGE_MODE_CODES.join(', ')})."

          expected_code = prior_by_sequence.key?(entry.sequence) ? 'changed' : 'added'
          descriptor = expected_code == 'added' ? 'newly added' : 'modified or canceled'
          assert code == expected_code,
                 "The infoChanged extension on the #{kind} (sequence #{entry.sequence}) in the " \
                 "#{comparison[:current_label]} has valueCode '#{code}', but an entry that was #{descriptor} " \
                 "relative to the #{comparison[:prior_label]} SHALL use valueCode '#{expected_code}' per the " \
                 'value set definitions.'
        end
      end
    end
  end
end
