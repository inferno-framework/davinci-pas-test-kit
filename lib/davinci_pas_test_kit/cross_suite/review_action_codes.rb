require_relative 'pas_constants'

module DaVinciPASTestKit
  # Reads the X12 review action codes on ClaimResponse item adjudications from parsed JSON. Responses may be
  # tester-provided, so anything that isn't the expected kind of JSON value is ignored rather than raising.
  # Callers with FHIR models pass their to_hash, since fhir_models drops a whole resource when any of its
  # elements is malformed.
  module ReviewActionCodes
    # @param claim_response [Hash] a ClaimResponse as parsed JSON
    # @param code [String] e.g. PASConstants::X12_ADJUDICATION_CODES[:pended]
    def self.claim_response_has_code?(claim_response, code)
      claim_response.is_a?(Hash) && hashes(claim_response['item']).any? { |item| item_has_code?(item, code) }
    end

    # @param item [Hash] a ClaimResponse.item as parsed JSON
    # @param code [String]
    def self.item_has_code?(item, code)
      item.is_a?(Hash) && hashes(item['adjudication']).any? { |adjudication| codes(adjudication).include?(code) }
    end

    # @param adjudication [Hash] a ClaimResponse.item.adjudication as parsed JSON
    # @return [Array<String>]
    def self.codes(adjudication)
      extensions(adjudication, PASConstants::REVIEW_ACTION_EXTENSION_URL)
        .flat_map { |review_action| extensions(review_action, PASConstants::REVIEW_ACTION_CODE_EXTENSION_URL) }
        .map { |code_extension| code_extension['valueCodeableConcept'] }
        .grep(Hash)
        .flat_map { |concept| hashes(concept['coding']).map { |coding| coding['code'] } }
        .grep(String)
    end

    def self.extensions(element, url)
      return [] unless element.is_a?(Hash)

      hashes(element['extension']).select { |extension| extension['url'] == url }
    end

    # The Hash elements of a JSON array
    def self.hashes(value)
      value.is_a?(Array) ? value.grep(Hash) : []
    end
  end
end
