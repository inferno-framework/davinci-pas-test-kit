# require 'securerandom' //used for attestation experiment - see below
# require_relative '../../../urls' // used for attestation experiment - see below

module DaVinciPASTestKit
  module DaVinciPASV201
    class PasClaimStatusTest < Inferno::Test
      # include URLs // used for attestation experiment - see below

      id :prior_auth_claim_status
      title 'Server returns the expected authorization response'
      description %(
        This test aims to confirm that the status of the prior authorization matches
        the anticipated status for the workflow under examination.
        (NOT YET IMPLEMENTED)
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

        # TODO: Implement subscription for pended: Inferno will subscribe to the server to receive notification
        # when the submitted claim status will be updated.
        if use_case == 'pended'
          # rubocop:disable Layout/LineLength
          wait(
            identifier: use_case,
            message: %(
              Inferno has received a 'Pended' claim response as expected.

              Please
              **[click
              here](#{Inferno::Application['base_url']}/custom/davinci_pas_server_suite_v201/resume_after_notification?use_case=#{use_case})**
              when the status of this claim has been finalized to inform Inferno to resume testing.

              Future versions of this test may implement automated monitoring
              capabilities described in the implementation guide.
            )
          )
          # rubocop:enable Layout/LineLength
        end
      end
    end
  end
end
