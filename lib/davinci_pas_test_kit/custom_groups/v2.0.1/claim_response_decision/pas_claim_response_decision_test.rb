# require 'securerandom' //used for attestation experiment - see below
# require_relative '../../../urls' // used for attestation experiment - see below

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClaimResponseDecisionTest < Inferno::Test
      # include URLs // used for attestation experiment - see below

      id :prior_auth_claim_response_decision_validation
      title 'Server response includes the expected decision code in the ClaimResponse instance'
      description %(
        This test aims to confirm that the decision in the returned ClaimResponse matches
        the decision code required for the workflow under examination.
        (NOT YET IMPLEMENTED - see details on this limitation
        [here](https://github.com/inferno-framework/davinci-pas-test-kit/tree/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations))
      )
      uses_request :pa_submit

      def status
        if use_case == 'approval'
          'approved'
        else
          use_case == 'denial' ? 'denied' : 'pended'
        end
      end

      run do
        # Experiment with extraction of statuses and use in an attestation
        # Not used due to the following problems:
        # - no real clients to test with
        # - how to express the location we're looking for? The spec never mentions it explicitly.
        #
        # # Extract the response status
        # status_values = []
        # if resource.resourceType == 'Bundle'
        #   resource.entry.each do |one_entry|
        #     next unless one_entry.resource.resourceType == 'ClaimResponse'
        #
        #     one_entry.resource.item.each do |one_item|
        #       one_item.adjudication.each do |one_adjudication|
        #         one_adjudication.extension
        #           .select { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction' }
        #           .each do |review_action_ext|
        #             review_action_ext.extension.select { |ext| ext.url == 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode' }
        #               .each do |review_action_code_ext|
        #                 review_action_code_ext.valueCodeableConcept.coding.select { |coding| coding.system == 'https://codesystem.x12.org/005010/306' }
        #                   .each do |one_code|
        #                     if one_code.code
        #                       status_values << "#{one_code.code}#{one_code.display ? " (#{one_code.display})" : ''}"
        #                     end
        #                   end
        #               end
        #           end
        #       end
        #     end
        #   end
        # end
        #
        # assert !status_values.empty?, 'No status values found **where??**'
        #
        # # Attestation
        # attestation_key = SecureRandom.uuid
        # status_display = status_values.reduce('') { |result, status| result + "- #{status}\n" }
        # wait(
        #   identifier: attestation_key,
        #   message: %(
        #     **Status Validation for `#{status}`**:
        #
        #     The following adjudication status
        #     #{status_values.length > 1 ? 'values were' : 'value was'}
        #     found in the response **where??**:
        #
        #     #{status_display}
        #
        #     I attest that
        #     #{status_values.length > 1 ? 'one of the status values' : 'the status value'}
        #     returned by the server indicates that the request was #{status}
        #
        #     [Click here](#{resume_pass_url}?token=#{attestation_key}) if the above statement is **true**.
        #
        #     [Click here](#{resume_fail_url}?token=#{attestation_key}) if the above statement is **false**.
        #   )
        # )
        #
        # end of experiment with attestation code
      end
    end
  end
end
