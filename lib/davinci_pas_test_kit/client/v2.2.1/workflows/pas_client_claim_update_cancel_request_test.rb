require_relative 'pas_client_claim_update_validation_utils'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Checks that the cancel-entire-request update carries a certificationType extension with code 3
    # (Cancel) in Claim.extension, as described in the IG's "updating authorization requests" narrative.
    # This behavior has no numbered conformance statement to link, so there is no verifies_requirements
    # annotation.
    class PASClientClaimUpdateCancelRequestTest < Inferno::Test
      include ClaimUpdateValidationUtils

      id :pas_client_v221_claim_update_cancel_request_test
      title 'Cancel-entire-request update carries a certificationType extension with code 3'
      description %(
        To [cancel the entire request](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#updating-authorization-requests),
        clients send a [certificationType extension](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-extension-certificationType.html)
        with a code of 3 (Cancel) in the `Claim.extension` element of a PAS Claim Update; no items are needed to
        cancel the entire authorization. This test checks the cancel-entire-request update and confirms it
        carries that extension.
      )

      run do
        bundle = claim_update_bundle(CLAIM_UPDATE_CANCEL_ALL_TAG)
        claim = first_claim(bundle)
        skip_if claim.nil?, 'No cancel-entire-request update was received to verify.'

        assert certification_type_cancel?(claim),
               'The cancel-entire-request update must include a certificationType extension with a code of 3 ' \
               '(Cancel) in Claim.extension.'
      end
    end
  end
end
