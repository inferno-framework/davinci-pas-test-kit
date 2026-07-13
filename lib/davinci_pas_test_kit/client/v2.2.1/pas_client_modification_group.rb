require_relative 'workflows/pas_client_modification_submit_test'
require_relative 'workflows/pas_client_modification_verification_test'
require_relative 'workflows/pas_client_response_attest'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientModificationGroup < Inferno::TestGroup
      id :pas_client_v221_modification_group
      title 'Payer Modifications'
      description %(
        During these tests, the client will initiate a prior authorization request and show it can
        respond appropriately to a response in which the payer authorizes items that differ from those
        that were requested.

        In PAS v2.2.1, payers are permitted to
        [return items that are different from what was requested](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#returning-authorized-items-that-are-different-from-what-was-requested).
        When this happens, each requested item is returned in the `ClaimResponse.item` with an adjudication
        status of A6 ('Modified') and the details of what was actually authorized are returned in a
        corresponding `ClaimResponse.addItem`. Clients must be able to process these responses and make the
        details of the authorized items available to their users.
      )
      run_as_group

      input :modification_json_response, optional: true

      test from: :pas_client_v221_modification_submit_test
      test from: :pas_client_v221_request_bundle_validation_test,
           config: { options: { workflow_tag: MODIFICATION_WORKFLOW_TAG } }

      test from: :pas_client_v221_response_bundle_validation_test,
           config: { options: { workflow_tag: MODIFICATION_WORKFLOW_TAG } }
      test from: :pas_client_v221_modification_verification_test

      test from: :pas_client_v221_response_attest,
           title: 'PAS client makes the details of the payer-authorized items available',
           description: %(
             This test provides the tester an opportunity to observe their client following
             the receipt of the payer modification response and attest that users are able to
             determine the details of what was actually authorized by the payer.
           ),
           config: { options: {
             workflow_tag: MODIFICATION_WORKFLOW_TAG,
             attest_message: 'I attest that the details of what the payer actually authorized, including any ' \
                             'modifications made to the requested items, were made available to users in the ' \
                             'client system.'
           } }
    end
  end
end
