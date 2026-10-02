# frozen_string_literal: true

module DaVinciPASTestKit
  # Validates that resources referenced within a FHIR resource are present exactly once in a
  # given set of bundle entries. Kept independent of PasBundleValidation's profile-conformance
  # logic so it can be included on its own (e.g. by tests that only need reference-presence
  # checks, such as PASClientClaimUpdateReferencedResourcesTest).
  module ReferencedResourcePresenceValidation
    # This method traverses references within a FHIR resource, ensuring that referenced resources
    # are populated in the bundle. It also enforces that a referenced resource appears only once in the bundle,
    # as required by the PAS IG.
    # @param target_resource [FHIR::Model] The FHIR resource to traverse and validate.
    # @param base_url [String] The server base url.
    # @param resources_to_match [Array<FHIR:Bundle:Entry] The list of FHIR bundle entries to match references against.
    # @param skip_claim_related [Boolean] When true, a Claim's `related` element is not traversed. This is set
    #   for any Claim reached by following a reference (i.e. a non-primary Claim in a Claim Update chain), whose
    #   own Claim.related.claim (the grandparent) is deliberately omitted from the Bundle per spec-65/66. The
    #   primary Claim passed in by the caller keeps `skip_claim_related: false`, so its parent reference - and the
    #   parent's own referenced resources - are still checked.
    # @return [Array<String>] The error messages found during traversal.
    def check_presence_of_referenced_resources(target_resource, base_url, resources_to_match,
                                               skip_claim_related: false)
      # Indexed once per call rather than linearly scanned per reference encountered during the
      # traversal below. Grouped (not a plain Hash) so a fullUrl appearing on more than one entry
      # is still detected as an error instead of being silently collapsed to the last match.
      entries_by_full_url = resources_to_match.group_by(&:fullUrl)
      traverse_referenced_resources(target_resource, base_url, entries_by_full_url,
                                    skip_claim_related:, errors: [])
    end

    # ClaimResponse.request is a back-reference to the submitted Claim. The PAS IG response bundle
    # profile (profile-pas-response-bundle) has no required Claim entry slice, so the Claim need
    # not be present in the response bundle. Skipping here matches the identical guard in
    # ResponseGenerator#referenced_entities, which also skips ClaimResponse.request when
    # building mock response bundles.
    def claim_response_request_attr?(resource, attr)
      attr.to_s == 'request' &&
        resource.respond_to?(:resourceType) &&
        resource.resourceType == 'ClaimResponse'
    end

    # Claim.related.claim points to the Claim being updated. For a non-primary Claim in a Claim Update
    # chain (one reached by following a reference), that prior Claim is the grandparent, which spec-65/66
    # require to be omitted from the Bundle. Used with the `skip_claim_related` flag so the generic
    # reference-presence check does not flag the deliberately-omitted grandparent as missing.
    def claim_related_attr?(resource, attr)
      attr.to_s == 'related' &&
        resource.respond_to?(:resourceType) &&
        resource.resourceType == 'Claim'
    end

    # Generates a message for a resource that appears more than once in a bundle.
    #
    # @param reference_resource_type [String] The resource type being referenced.
    # @param reference_resource_id [String] The resource ID being referenced.
    # @param total_matches [Integer] The total number of matches found in the bundle.
    #
    # This method generates an error message when a referenced resource appears more than once
    # in a FHIR bundle, which is not allowed.
    def resource_shall_appear_once_message(absolute_ref, total_matches)
      " The referenced #{absolute_ref} resource SHALL appear exactly once in the Bundle, but found #{total_matches}."
    end

    def absolute_url(reference, base_url)
      return if reference.blank?
      return reference if base_url.blank? || reference.starts_with?('urn:uuid:') || URI(reference).absolute?

      "#{base_url}/#{reference}"
    end

    # Extracts the base URL from an absolute URL by removing the resource type and ID.
    # @param absolute_url [String] The absolute URL.
    # @return [String] The base URL, or an empty string if the URL format is not as expected.
    def extract_base_url(absolute_url)
      return '' if absolute_url.blank?

      uri = URI(absolute_url)
      return '' unless uri.scheme && uri.host

      # Split the path segments and remove the last two segments (resource type and id)
      path_segments = uri.path.split('/')
      base_path = path_segments[0...-2].join('/')

      "#{uri.scheme}://#{uri.authority}#{base_path}"
    end

    private

    # Recursive worker for check_presence_of_referenced_resources; errors is threaded through the
    # recursive calls and is private so callers can't pass in (and so corrupt) their own accumulator.
    # entries_by_full_url is a fullUrl => Array<Bundle::Entry> index built once by the public method,
    # so each reference encountered is an O(1) lookup instead of a linear scan of every entry.
    def traverse_referenced_resources(target_resource, base_url, entries_by_full_url, skip_claim_related:, errors:)
      return errors if target_resource.blank?

      if target_resource.is_a?(FHIR::Reference) && target_resource.reference.present?
        ref = target_resource.reference
        absolute_ref = absolute_url(ref, base_url)
        matching_resources = entries_by_full_url[absolute_ref] || []

        if matching_resources.length != 1
          errors << resource_shall_appear_once_message(absolute_ref, matching_resources.length)
        end

        if matching_resources.length.positive?
          # A resource reached by following a reference is an included resource, not the primary Claim
          # being validated; if it is itself a Claim Update, its referenced grandparent Claim is omitted.
          traverse_referenced_resources(matching_resources.first.resource, base_url, entries_by_full_url,
                                        skip_claim_related: true, errors:)
        end
      else
        target_resource.source_hash.each_key do |attr|
          next if claim_response_request_attr?(target_resource, attr)
          next if skip_claim_related && claim_related_attr?(target_resource, attr)

          value = target_resource.send(attr.to_sym)
          if value.is_a?(FHIR::Model)
            traverse_referenced_resources(value, base_url, entries_by_full_url, skip_claim_related:, errors:)
          elsif value.is_a?(Array) && value.all?(FHIR::Model)
            value.each do |elmt|
              traverse_referenced_resources(elmt, base_url, entries_by_full_url, skip_claim_related:, errors:)
            end
          end
        end
      end

      errors
    end
  end
end
