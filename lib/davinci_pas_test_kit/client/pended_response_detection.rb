require_relative '../cross_suite/pas_constants'
require_relative '../cross_suite/review_action_codes'

module DaVinciPASTestKit
  # Identifies pended v2.2.1 $submit responses, which have a review action code of A4 (Pending) on a
  # ClaimResponse item adjudication
  module PendedResponseDetection
    # @param response [Hash, String, nil] a $submit response Bundle, as JSON or parsed from it (string keys)
    def self.pended?(response)
      bundle = response.is_a?(String) ? JSON.parse(response) : response
      return false unless bundle.is_a?(Hash) && bundle['resourceType'] == 'Bundle'

      claim_responses = ReviewActionCodes.hashes(bundle['entry']).map { |entry| entry['resource'] }
        .select { |resource| resource.is_a?(Hash) && resource['resourceType'] == 'ClaimResponse' }
      claim_responses.any? do |claim_response|
        ReviewActionCodes.claim_response_has_code?(claim_response, PASConstants::X12_ADJUDICATION_CODES[:pended])
      end
    rescue JSON::ParserError
      false
    end
  end
end
