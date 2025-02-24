require_relative '../../../urls'
require_relative '../../../session_identification'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubmitMustSupportTest < Inferno::Test
      include URLs
      include SessionIdentification

      id :pas_client_submit_v201_must_support_test
      title 'Client submits claims using the $submit operation to demonstrate coverage of must support elements'
      description %(
        This test allows the client to send $submit requests in addition to any already sent in previous test groups
        for Inferno to evaluate coverage of must support elements.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@58', 'hl7.fhir.us.davinci-pas_2.0.1@62',
                            'hl7.fhir.us.davinci-pas_2.0.1@70', 'hl7.fhir.us.davinci-pas_2.0.1@202'

      input :client_id,
            optional: true
      input :session_url_path,
            optional: true
      config options: { accepts_multiple_requests: true }

      run do
        wait_identifier = inputs_to_wait_identifier(client_id, session_url_path)
        submit_endpoint = inputs_to_session_endpont(:submit, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: %(
            The client system may now make multiple $submit requests before continuing. These requests should
            cumulatively demonstrate coverage of all required profiles and all must support elements within those
            profiles, as specified by the DaVince Prior Authorization Support implementation guide.

            For the $submit operation the required profiles include:
            - PAS Request Bundle
            - PAS Claim Update
            - PAS Coverage
            - PAS Beneficiary Patient
            - PAS Subscriber Patient
            - PAS Insurer Organization
            - PAS Requestor Organization
            - PAS Practitioner
            - PAS PractitionerRole
            - PAS Encounter
            - At least one of the following request profiles
              - PAS Device Request
              - PAS Medication Request
              - PAS Nutrition Order
              - PAS Service Request

            Submit PAS requests to

            `#{submit_endpoint}`

            and [click here](#{resume_pass_url}?token=#{wait_identifier}) when done.
          )
        )
      end
    end
  end
end
