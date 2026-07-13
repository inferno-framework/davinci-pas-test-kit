require_relative 'client_input_descriptions'
require_relative 'session_identification'

module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractGatherMustSupportTest < Inferno::Test
    include SessionIdentification

    id :pas_client_gather_must_support
    title 'PAS client submits Claims using the $submit and $inquire operations to demonstrate coverage of must support elements'
    description %(
      This test allows the client to send both $submit and $inquire requests for Inferno to evaluate
      coverage of must support elements in both requests and responses. Any requests made during
      previous workflow tests will also be considered.

      Because Inferno's mocked responses do not cover all must support elements, in order to pass
      these tests testers will need to provide response bundles for Inferno to return when
      responding to $submit and $inquire requests. Each response input takes a single entry or a
      JSON list of entries, where each entry is either a FHIR Bundle or a wrapper object pairing
      a Bundle with selection criteria. For each request, Inferno will respond with the Bundle of
      the first entry whose criteria are all met, generating a default response if none match.
      See the input descriptions for details on the wrapper format, the supported criteria, and
      on substituting values from the request into the returned response.

      This enables testers to verify that their client can handle responses containing all required
      must support elements.
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
    input :ms_submit_responses,
          title: 'Must Support $submit Response Bundles',
          type: 'textarea',
          optional: true,
          description: %(
            An optional JSON value specifying response Bundles for Inferno to return when
            responding to $submit requests during must support testing. Provide a single entry
            or a list of entries, where each entry is either a FHIR Bundle or a wrapper object
            of the form `{"criteria": {...}, "bundle": {...}}` pairing a FHIR Bundle with the
            selection criteria that a request must meet for that Bundle to be returned.

            For each request, Inferno will respond with the Bundle of the first entry whose
            criteria are all met. An entry with no criteria (including a bare Bundle) matches
            any request, and an entry with multiple criteria must meet all of them. If no entry
            matches, or none are provided, Inferno will generate a default response. Supported
            `criteria` keys:

            - `requestRange`: a string of comma-separated request numbers or ranges, e.g.,
              `"1-2,4"`. Met when the number of $submit requests received during this test,
              counting this one, is among the listed values.
            - `fhirpath`: a FHIRPath expression evaluated against the incoming request Bundle.
              Met when the expression evaluates to a single truthy value.

            A Bundle may also contain tokens of the form `{{fhirpath}}`, e.g.,
            `{{Bundle.entry.first().resource.id}}`. Inferno replaces each token in the returned
            Bundle with the result of evaluating the FHIRPath expression against the incoming
            request Bundle.
          )
    input :ms_inquire_responses,
          title: 'Must Support $inquire Response Bundles',
          type: 'textarea',
          optional: true,
          description: %(
            An optional JSON value specifying response Bundles for Inferno to return when
            responding to $inquire requests during must support testing. Provide a single entry
            or a list of entries, where each entry is either a FHIR Bundle or a wrapper object
            of the form `{"criteria": {...}, "bundle": {...}}` pairing a FHIR Bundle with the
            selection criteria that a request must meet for that Bundle to be returned.

            For each request, Inferno will respond with the Bundle of the first entry whose
            criteria are all met. An entry with no criteria (including a bare Bundle) matches
            any request, and an entry with multiple criteria must meet all of them. If no entry
            matches, or none are provided, Inferno will generate a default response. Supported
            `criteria` keys:

            - `requestRange`: a string of comma-separated request numbers or ranges, e.g.,
              `"1-2,4"`. Met when the number of $inquire requests received during this test,
              counting this one, is among the listed values.
            - `fhirpath`: a FHIRPath expression evaluated against the incoming request Bundle.
              Met when the expression evaluates to a single truthy value.

            A Bundle may also contain tokens of the form `{{fhirpath}}`, e.g.,
            `{{Bundle.entry.first().resource.id}}`. Inferno replaces each token in the returned
            Bundle with the result of evaluating the FHIRPath expression against the incoming
            request Bundle.
          )
    config options: { accepts_multiple_requests: true }
    output :confirmation_url

    run do
      wait_identifier = session_wait_identifier(client_id, session_url_path)
      submit_endpoint = session_endpoint_url(:submit, client_id, session_url_path)
      inquire_endpoint = session_endpoint_url(:inquire, client_id, session_url_path)
      confirmation_url = "#{resume_pass_url}?token=#{wait_identifier}"
      output(confirmation_url:)

      wait(
        identifier: wait_identifier,
        message: %(
          The client system may now make multiple $submit and $inquire requests before continuing.
          These requests should cumulatively demonstrate coverage of all required profiles and all
          must support elements within those profiles, as specified by the DaVinci Prior Authorization
          Support implementation guide.

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

          If you would like Inferno to respond with specific response bundles (to demonstrate
          must support coverage on responses), provide them in the input fields above.

          Submit PAS $submit requests to

          `#{submit_endpoint}`

          Submit PAS $inquire requests to

          `#{inquire_endpoint}`

          and [click here](#{confirmation_url}) when done.
        )
      )
    end
  end
end
