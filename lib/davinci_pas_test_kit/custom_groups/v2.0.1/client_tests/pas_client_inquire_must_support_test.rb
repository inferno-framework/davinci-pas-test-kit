require_relative '../../../urls'
require_relative '../../../descriptions'
require_relative '../../../session_identification'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientInquireMustSupportTest < Inferno::Test
      include URLs
      include SessionIdentification

      id :pas_client_inquire_v201_must_support_test
      title 'Client inquires about claims using the $inquire operation to demonstrate coverage of must support elements'
      description %(
        This test allows the client to send $inquire requests in addition to any already sent in previous test groups
        for Inferno to evaluate coverage of must support elements.
      )
      input :client_id,
            title: 'Client Id',
            type: 'text',
            optional: true,
            locked: true,
            description: INPUT_CLIENT_ID_LOCKED
      input :session_url_path,
            title: 'Session-specific URL path extension',
            type: 'text',
            optional: true,
            locked: true,
            description: INPUT_SESSION_URL_PATH_LOCKED
      config options: { accepts_multiple_requests: true }

      run do
        wait_identifier = inputs_to_wait_identifier(client_id, session_url_path)
        inquire_endpoint = inputs_to_session_endpont(:inquire, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          message: %(
            The client system may now make multiple $inquire requests before continuing. These requests should
            cumulatively demonstrate coverage of all required profiles and all must support elements within those
            profiles, as specified by the DaVince Prior Authorization Support implementation guide.

            For the $inquire operation the required profiles include:
            - PAS Inquiry Request Bundle
            - PAS Claim Inquiry
            - PAS Coverage
            - PAS Beneficiary Patient
            - PAS Subscriber Patient
            - PAS Insurer Organization
            - PAS Requestor Organization
            - PAS Practitioner
            - PAS PractitionerRole

            Submit PAS requests to

            `#{inquire_endpoint}`

            and [click here](#{resume_pass_url}?token=#{wait_identifier}) when done.
          )
        )
      end
    end
  end
end
