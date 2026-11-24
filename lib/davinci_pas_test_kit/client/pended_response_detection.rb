require_relative '../cross_suite/pas_constants'
require_relative '../cross_suite/review_action_codes'

module DaVinciPASTestKit
  # Identifies pended v2.2.1 $submit responses, which have a review action code of A4 (Pending) on a
  # ClaimResponse item adjudication
  module PendedResponseDetection
    # @param response [Hash, String, nil] a $submit response Bundle, parsed or as JSON
    def self.pended?(response)
      json = response.is_a?(Hash) ? response.to_json : response
      return false unless json.is_a?(String)

      bundle = FHIR.from_contents(json)
      return false unless bundle.is_a?(FHIR::Bundle)

      ReviewActionCodes.elements(bundle.entry).map(&:resource).grep(FHIR::ClaimResponse).any? do |claim_response|
        ReviewActionCodes.claim_response_has_code?(claim_response, PASConstants::X12_ADJUDICATION_CODES[:pended])
      end
    rescue JSON::ParserError
      false
    end
  end
end
