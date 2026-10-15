require_relative 'attestation_instructions'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ClientSecurityAttestationTest < Inferno::Test
      id :pas_client_v221_security_attestation
      ATTESTATION_TITLE = 'Health IT module adheres to security and privacy requirements'.freeze
      title ATTESTATION_TITLE
      description %(
        During this test, the tester will confirm that the Health IT module adheres to security and
        privacy requirements including those defined in the HRex specification. To see the specifics
        of the attested requirements, click the "View Specification Requirements" link for this test.
      )
      attestation
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-4'
      input_instructions ATTESTATION_INPUT_INSTRUCTIONS

      input :security_attestation,
            title: ATTESTATION_TITLE,
            description: %(
              I attest that the Health IT module adheres to security and
              privacy requirements including those defined in the HRex specification.
            ),
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                { label: 'Yes', value: 'true' },
                { label: 'No', value: 'false' }
              ]
            }
      input :security_attestation_note,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert security_attestation == 'true'
      end
    end
  end
end
