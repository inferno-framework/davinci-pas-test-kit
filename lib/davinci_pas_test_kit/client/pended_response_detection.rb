require_relative '../cross_suite/response_template'

module DaVinciPASTestKit
  # Identifies pended v2.2.1 $submit responses, which have a review action code of A4 (Pending) on a
  # ClaimResponse item adjudication
  module PendedResponseDetection
    REVIEW_ACTION_URL = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'.freeze
    REVIEW_ACTION_CODE_URL = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'.freeze
    PENDED_REVIEW_ACTION_CODE = 'A4'.freeze

    # @param response [Hash, String, nil] a $submit response Bundle, parsed or as JSON
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

    # The Hash elements of a JSON array, ignoring anything else in tester-provided content. A response
    # template's $forEach object counts as its template, so that the codes in repeated items are found.
    def self.hashes(value)
      return [] unless value.is_a?(Array)

      value.grep(Hash).map { |hash| hash.fetch(ResponseTemplate::FOR_EACH_KEY, nil) ? hash['template'] : hash }
        .grep(Hash)
    end
  end
end
