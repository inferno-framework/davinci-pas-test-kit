require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-69
    class PASClientClaimUpdateCancelledEntriesTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_cancelled_entries_test
      title 'Canceled entries carry the infoCancelled modifier extension'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-69)
        that item and supportingInfo entries removed from the request include the infoCancelled modifier
        extension with a valueBoolean of `true`. This test checks each Claim Update for entries marked as
        canceled and confirms the infoCancelled modifier extension is present and `true`.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-69',
                            'hl7.fhir.us.davinci-pas_2.2.1@prof-7',
                            'hl7.fhir.us.davinci-pas_2.2.1@prof-8'

      run do
        steps = received_claim_update_steps
        skip_if steps.empty?, 'No Claim Update requests were received to verify.'

        cancelled_entries = steps.flat_map do |step|
          (Array(step[:claim].item) + Array(step[:claim].supportingInfo))
            .select { |entry| cancellation_marked?(entry) }
            .map { |entry| { step:, entry: } }
        end

        skip_if cancelled_entries.empty?,
                'No canceled item or supportingInfo entries were received to verify (the modify-and-cancel ' \
                'update is expected to cancel an item).'

        cancelled_entries.each do |cancelled|
          entry = cancelled[:entry]
          next if info_cancelled?(entry)

          add_message('error',
                      "A canceled #{entry_kind(entry)} (sequence #{entry.sequence}) in the " \
                      "#{cancelled[:step][:label]} must include the infoCancelled modifier extension with a " \
                      'valueBoolean of true.')
        end

        assert_no_error_messages('One or more canceled entries did not carry the infoCancelled modifier ' \
                                 'extension. See Messages for details.')
      end
    end
  end
end
