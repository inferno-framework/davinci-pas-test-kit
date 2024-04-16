require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSubmitMustSupportTest < Inferno::Test
      include URLs

      id :pas_client_submit_v201_must_support_test
      title 'Client submits claims using the $submit operation to demonstrate coverage of must support elements'
      description %(
        This test allows the client to send $submit requests in addition to any already sent in previous test groups
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

            `#{submit_url}`

            and [click here](#{resume_pass_url}?token=#{access_token}) when done.
          )
        )
      end
    end
  end
end
