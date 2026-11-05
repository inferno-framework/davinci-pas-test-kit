module DaVinciPASTestKit
  # Identifies v2.2.1 $submit responses that pend the prior authorization decision, which PAS v2.2.1
  # conveys with a review action code of A4 (Pending) on a ClaimResponse item adjudication, since its
  # ClaimResponse outcome value set has no 'queued' code.
  module PendedResponseDetection
    REVIEW_ACTION_URL = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'.freeze
    REVIEW_ACTION_CODE_URL = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'.freeze
    PENDED_REVIEW_ACTION_CODE = 'A4'.freeze

    # @param response [Hash, String, nil] a $submit response Bundle, parsed or as JSON. Content that is
    #   not a Bundle, or not JSON, is not pended.
    # @return [Boolean] whether any ClaimResponse item adjudication in the Bundle has the pended review action code.
    def self.pended?(response)
      bundle = response.is_a?(String) ? JSON.parse(response) : response
      claim_responses(bundle).any? { |claim_response| pended_claim_response?(claim_response) }
    rescue JSON::ParserError
      false
    end

    def self.claim_responses(bundle)
      return [] unless bundle.is_a?(Hash) && bundle['resourceType'] == 'Bundle'

      hashes(bundle['entry']).map { |entry| entry['resource'] }
        .select { |resource| resource.is_a?(Hash) && resource['resourceType'] == 'ClaimResponse' }
    end

    def self.pended_claim_response?(claim_response)
      adjudications = hashes(claim_response['item']).flat_map { |item| hashes(item['adjudication']) }
      adjudications.any? { |adjudication| review_action_codes(adjudication).include?(PENDED_REVIEW_ACTION_CODE) }
    end

    def self.review_action_codes(adjudication)
      review_actions = extensions(adjudication, REVIEW_ACTION_URL)
      review_actions.flat_map { |review_action| extensions(review_action, REVIEW_ACTION_CODE_URL) }
        .map { |code_extension| code_extension['valueCodeableConcept'] }
        .grep(Hash)
        .flat_map { |concept| hashes(concept['coding']).map { |coding| coding['code'] } }
    end

    def self.extensions(element, url)
      hashes(element['extension']).select { |extension| extension['url'] == url }
    end

    # The Hash elements of a JSON array value, ignoring anything else, since the content may be tester-provided.
    def self.hashes(value)
      value.is_a?(Array) ? value.grep(Hash) : []
    end
  end
end
