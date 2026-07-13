require_relative '../../../cross_suite/tags'

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
          { label: step[:label], claim: first_claim(bundle) }
        end

        claims.each_cons(2).filter_map do |prior, current|
          next if prior[:claim].nil? || current[:claim].nil?

          { prior: prior[:claim], current: current[:claim],
            prior_label: prior[:label], current_label: current[:label] }
        end
      end

      # Finds the bundle entry that a reference points to, accommodating absolute fullUrls,
      # urn:uuid fullUrls, and relative "ResourceType/id" references.
      # NOTE: purposefully more permissive than strict FHIR Bundle reference resolution logic
      # to allow for evaluation. Other steps will catch issues like missing fullUrl values.
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

      def entry_sequences(entries)
        Array(entries).map(&:sequence).compact
      end

      def index_by_sequence(entries)
        Array(entries).to_h { |entry| [entry.sequence, entry] }
      end

      def entry_kind(entry)
        entry.class.name.to_s.split('::').last == 'Item' ? 'item' : 'supportingInfo'
      end

      # Returns true if the element (an item or the Claim itself) carries a certificationType
      # extension with code 3 (Cancel).
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
  end
end
