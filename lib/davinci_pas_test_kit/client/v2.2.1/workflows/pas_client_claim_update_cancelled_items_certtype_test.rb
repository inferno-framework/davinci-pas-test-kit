require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # spec-70
    class PASClientClaimUpdateCancelledItemsCertificationTypeTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_cancelled_items_certtype_test
      title 'Canceled items carry a certificationType extension with code 3'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-70)
        that canceled items additionally contain a certificationType extension with a code of 3 (Cancel) in the
        `Claim.item.extension` element. This test checks each Claim Update for canceled items and confirms the
        certificationType Cancel extension is present.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-70'

      run do
        steps = received_claim_update_steps
        skip_if steps.empty?, 'No Claim Update requests were received to verify.'

        cancelled_items = steps.flat_map do |step|
          Array(step[:claim].item)
            .select { |item| cancellation_marked?(item) }
            .map { |item| { step:, item: } }
        end

        skip_if cancelled_items.empty?,
                'No canceled items were received to verify (the modify-and-cancel update is expected to ' \
                'cancel an item).'

        cancelled_items.each do |cancelled|
          item = cancelled[:item]
          next if certification_type_cancel?(item)

          add_message('error',
                      "A canceled item (sequence #{item.sequence}) in the #{cancelled[:step][:label]} must " \
                      'contain a certificationType extension with a code of 3 (Cancel) in Claim.item.extension.')
        end

        assert_no_error_messages('One or more canceled items did not carry a certificationType extension with ' \
                                 'code 3 (Cancel).')
      end
    end
  end
end
