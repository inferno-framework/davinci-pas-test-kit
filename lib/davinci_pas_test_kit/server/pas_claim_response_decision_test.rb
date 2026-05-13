require_relative '../cross_suite/pas_constants'
require_relative '../cross_suite/tags'

module DaVinciPASTestKit
  class PasClaimResponseDecisionTest < Inferno::Test
    id :prior_auth_claim_response_decision_validation
    title 'Server response includes the expected decision code in the ClaimResponse instance'
    description %(
      This test checks that the decision in the returned ClaimResponse matches
      the decision code required for the workflow under examination.
    )

    def use_case
      config.options[:use_case]
    end

    def operation
      config.options[:operation]
    end

    def target_adjudication_code
      @target_adjudication_code ||= PASConstants::X12_ADJUDICATION_CODES[use_case.to_sym]
    end

    def response_has_expected_adjudication_code?(response_bundle)
      response_bundle.resourceType == 'Bundle' && response_bundle.entry.any? do |entry|
        entry.resource&.resourceType == 'ClaimResponse' && entry.resource.item.any? do |item|
          item.adjudication.any? do |adjudication|
            adjudication.extension.any? do |adjudication_ext|
              next unless adjudication_ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction'

              adjudication_ext.extension.any? do |review_action_ext|
                next unless review_action_ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode'

                review_action_ext.valueCodeableConcept&.coding&.any? do |coding|
                  coding.system == 'https://codesystem.x12.org/005010/306' &&
                    coding.code == target_adjudication_code
                end
              end
            end
          end
        end
      end
    end

    def load_response_bundles
      requests = load_tagged_requests(DaVinciPASTestKit.use_case_tag(use_case),
                                      DaVinciPASTestKit.operation_tag(operation))
      resources = requests.map(&:response_body).uniq.map do |response_body|
        FHIR.from_contents(response_body)
      rescue StandardError
        nil
      end.compact

      resources.select { |response| response.is_a?(FHIR::Bundle) }
    end

    run do
      bundles_to_check = load_response_bundles

      skip_if bundles_to_check.blank?,
              "No Bundles to check - No $#{operation} requests made during the #{use_case.titleize} " \
              'workflow tests returned Bundles.'

      codes_ok = bundles_to_check.all? do |response_bundle|
        response_has_expected_adjudication_code?(response_bundle)
      end

      assert codes_ok,
             "One or more response Bundles did not have the expected adjudication code #{target_adjudication_code}."
    end
  end
end
