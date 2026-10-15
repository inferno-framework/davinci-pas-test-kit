require_relative 'attestation_instructions'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ClientSubscriptionErrorRecoveryAttestationTest < Inferno::Test
      id :pas_client_v221_subscription_error_recovery_attestation
      ATTESTATION_TITLE = 'PAS client can recover from Subscription errors'.freeze
      title ATTESTATION_TITLE
      description %(
        During this test, the tester will confirm that the PAS client can detect and recover
        from Subscription errors and take steps to restore notification delivery. To see the specifics
        of the attested requirements, click the "View Specification Requirements" link for this test.
      )
      attestation
      verifies_requirements 'hl7.fhir.uv.subscriptions_1.1.0@81', 'hl7.fhir.uv.subscriptions_1.1.0@82'
      input_instructions ATTESTATION_INPUT_INSTRUCTIONS

      input :subscription_error_recovery_attestation,
            title: ATTESTATION_TITLE,
            description: %(
              I attest that the PAS client can detect and recover
              from Subscription errors and take steps to restore notification delivery.
            ),
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                { label: 'Yes', value: 'true' },
                { label: 'No', value: 'false' }
              ]
            }
      input :subscription_error_recovery_attestation_note,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert subscription_error_recovery_attestation == 'true'
      end
    end
  end
end
