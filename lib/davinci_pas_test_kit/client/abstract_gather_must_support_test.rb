require_relative 'client_input_descriptions'
require_relative 'session_identification'

module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractGatherMustSupportTest < Inferno::Test
    include SessionIdentification

    id :pas_client_gather_must_support
    title 'Client submits claims using $submit and $inquire operations to demonstrate coverage of must support elements'
    description %(
      This test allows the client to send both $submit and $inquire requests for Inferno to evaluate
      coverage of must support elements in both requests and responses. Any requests made during
      previous workflow tests will also be considered.

      Because Inferno's mocked responses do not cover all must support elements, in order to pass
      these tests testers will need to provide response bundles for Inferno to return when
      responding to $submit and $inquire requests. Each response input takes either a single JSON
      FHIR Bundle or a JSON list of Bundles. For each request, Inferno will respond with the first
      Bundle in the list that meets its selection criteria, generating a default response if none
      match. See the input descriptions for details on specifying selection criteria on a Bundle
      and on substituting values from the request into the returned response.

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
            An optional JSON FHIR Bundle, or list of Bundles, for Inferno to return when responding
            to $submit requests during must support testing. For each request, Inferno will respond
            with the first Bundle in the list that meets its selection criteria. If none match, or
            if no Bundles are provided, Inferno will generate a default response.

            Selection criteria are specified using extensions placed in an `extension` array at the
            top level of a Bundle's JSON:

            - Request range (url `urn:inferno:pas:request-range`): a `valueString` containing
              comma-separated request numbers or ranges, e.g., `"1-2,4"`. Met when the number of
              $submit requests received during this test, counting this one, is among the listed values.
            - Inclusion criteria (url `urn:inferno:pas:inclusion-criteria`): a `valueExpression` whose
              `expression` contains a FHIRPath expression. Met when the expression evaluates to a
              single truthy value against the incoming request Bundle.

            A Bundle with no criteria extensions matches any request, and a Bundle with both criteria
            must meet both. Inferno removes these extensions from the Bundle before returning it.

            A Bundle may also contain tokens of the form `{{fhirpath}}`, e.g.,
            `{{Bundle.entry.first.resource.id}}`. Inferno replaces each token in the selected Bundle
            with the result of evaluating the FHIRPath expression against the incoming request Bundle.
          )
    input :ms_inquire_responses,
          title: 'Must Support $inquire Response Bundles',
          type: 'textarea',
          optional: true,
          description: %(
            An optional JSON FHIR Bundle, or list of Bundles, for Inferno to return when responding
            to $inquire requests during must support testing. For each request, Inferno will respond
            with the first Bundle in the list that meets its selection criteria. If none match, or
            if no Bundles are provided, Inferno will generate a default response.

            Selection criteria are specified using extensions placed in an `extension` array at the
            top level of a Bundle's JSON:

            - Request range (url `urn:inferno:pas:request-range`): a `valueString` containing
              comma-separated request numbers or ranges, e.g., `"1-2,4"`. Met when the number of
              $inquire requests received during this test, counting this one, is among the listed values.
            - Inclusion criteria (url `urn:inferno:pas:inclusion-criteria`): a `valueExpression` whose
              `expression` contains a FHIRPath expression. Met when the expression evaluates to a
              single truthy value against the incoming request Bundle.

            A Bundle with no criteria extensions matches any request, and a Bundle with both criteria
            must meet both. Inferno removes these extensions from the Bundle before returning it.

            A Bundle may also contain tokens of the form `{{fhirpath}}`, e.g.,
            `{{Bundle.entry.first.resource.id}}`. Inferno replaces each token in the selected Bundle
            with the result of evaluating the FHIRPath expression against the incoming request Bundle.
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
