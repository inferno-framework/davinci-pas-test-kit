module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClaimResponseDecisionTest < Inferno::Test
      X12_ADJUDICATION_CODES = {
        approval: 'A1',
        denial: 'A3',
        pended: 'A4'
      }.freeze

      id :prior_auth_claim_response_decision_validation
      title 'Server response includes the expected decision code in the ClaimResponse instance'
      description %(
        This test checks that the decision in the returned ClaimResponse matches
        the decision code required for the workflow under examination.
      )
      uses_request :pa_submit

      run do
        adjudication_code_present = resource&.resourceType == 'Bundle' && resource.entry.any? do |entry|
          entry.resource&.resourceType == 'ClaimResponse' && entry.resource.item.any? do |item|
            item.adjudication.any? do |adjudication|
              adjudication.extension.any? do |adjudication_ext|
                next unless adjudication_ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'

                adjudication_ext.extension.any? do |review_action_ext|
                  next unless review_action_ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'

                  review_action_ext.valueCodeableConcept&.coding&.any? do |coding|
                    coding.system == 'https://codesystem.x12.org/005010/306' &&
                      coding.code == X12_ADJUDICATION_CODES[use_case.to_sym]
                  end
                end
              end
            end
          end
        end

        assert adjudication_code_present, 'Claim Response did not contain expected adjudication status ' \
                                          "code '#{X12_ADJUDICATION_CODES[use_case.to_sym]}'"
      end
    end
  end
end
