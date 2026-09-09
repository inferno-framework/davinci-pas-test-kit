require_relative 'attestation_instructions'

module DaVinciPASTestKit
  module DaVinciPASV221
    class ProviderReviewAttestationTest < Inferno::Test
      id :pas_client_v221_provider_review_attestation
      ATTESTATION_TITLE = 'Health IT module allows but does not require providers to review information before ' \
                          'submitting'.freeze
      title ATTESTATION_TITLE
      description %(
        During this test, the tester will confirm that the Health IT module allows but does not require providers
        to review submission details before sending PAS prior authorization requests.
        To see the specifics of the attested requirements, click the "View Specification Requirements" link for this
        test.
      )
      attestation
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@priv-1', 'hl7.fhir.us.davinci-pas_2.2.1@use-5'
      input_instructions ATTESTATION_INPUT_INSTRUCTIONS

      input :provider_review_attestation,
            title: ATTESTATION_TITLE,
            description: %(
              I attest that the Health IT module allows but does not require providers to review
              submission details before sending PAS prior authorization requests.
            ),
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                { label: 'Yes', value: 'true' },
                { label: 'No', value: 'false' }
              ]
            }
      input :provider_review_attestation_note,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert provider_review_attestation == 'true'
      end
    end
  end
end
