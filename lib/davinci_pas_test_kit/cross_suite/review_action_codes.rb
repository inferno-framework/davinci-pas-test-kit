require_relative 'pas_constants'

module DaVinciPASTestKit
  # Reads the X12 review action codes on ClaimResponse item adjudications. Responses may be tester-provided,
  # and fhir_models leaves nil in place of array elements it can't build from malformed JSON, so nils are
  # skipped throughout.
  module ReviewActionCodes
    # @param claim_response [FHIR::ClaimResponse, nil]
    # @param code [String] e.g. PASConstants::X12_ADJUDICATION_CODES[:pended]
    def self.claim_response_has_code?(claim_response, code)
      elements(claim_response&.item).any? { |item| item_has_code?(item, code) }
    end

    # @param item [FHIR::ClaimResponse::Item, nil]
    # @param code [String]
    def self.item_has_code?(item, code)
      elements(item&.adjudication).any? { |adjudication| codes(adjudication).include?(code) }
    end

    # @param adjudication [FHIR::ClaimResponse::Item::Adjudication, nil]
    # @return [Array<String>]
    def self.codes(adjudication)
      extensions(adjudication, PASConstants::REVIEW_ACTION_EXTENSION_URL)
        .flat_map { |review_action| extensions(review_action, PASConstants::REVIEW_ACTION_CODE_EXTENSION_URL) }
        .flat_map { |code_extension| elements(code_extension.valueCodeableConcept&.coding) }
        .filter_map(&:code)
    end

    def self.extensions(element, url)
      elements(element&.extension).select { |extension| extension.url == url }
    end

    def self.elements(list)
      Array(list).compact
    end
  end
end
