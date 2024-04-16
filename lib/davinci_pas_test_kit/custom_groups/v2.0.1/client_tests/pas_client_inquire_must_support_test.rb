require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientInquireMustSupportTest < Inferno::Test
      include URLs

      id :pas_client_inquire_v201_must_support_test
      title 'Client inquires about claims using the $inquire operation to demonstrate coverage of must support elements'
      description %(
        This test allows the client to send $inquire requests in addition to any already sent in previous test groups
        for Inferno to evaluate coverage of must support elements.
      )
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )
      config options: { accepts_multiple_requests: true }

      run do
        wait(
          identifier: access_token,
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

            `#{inquire_url}`

            and [click here](#{resume_pass_url}?token=#{access_token}) when done.
          )
        )
      end
    end
  end
end
