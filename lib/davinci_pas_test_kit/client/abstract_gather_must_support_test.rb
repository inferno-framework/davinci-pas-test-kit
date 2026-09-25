require_relative 'client_input_descriptions'
require_relative 'session_identification'

module DaVinciPASTestKit
  # abstract test, needs to be extended to include a version-specific URLs module
  class AbstractGatherMustSupportTest < Inferno::Test
    include SessionIdentification
    include UserInputResponse

    id :pas_client_gather_must_support
    title 'PAS client submits Claims using the $submit and $inquire operations to demonstrate coverage of must ' \
          'support elements'
    description %(
      This test allows the client to send both $submit and $inquire requests for Inferno to evaluate
      coverage of must support elements in both requests and responses. Any requests made during
      previous workflow tests will also be considered.

      Because Inferno's mocked responses do not cover all must support elements, in order to pass
      these tests testers will need to provide response bundles for Inferno to return when
      responding to $submit and $inquire requests. Each response input takes a JSON list of entries,
      where each entry specifies a Bundle with selection criteria ([format](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-option-format)).
      For each request received during this test, Inferno will [select](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-option-evaluation)
      and [instantiate](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#response-instantiation)
      a response to return from this list. If no entries match or instantiation fails, Inferno will
      [mock](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Controlling-Simulated-Responses#mocked-responses)
      a response.

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
          description: DaVinciPASTestKit.ms_responses_input_description('$submit')
    input :ms_inquire_responses,
          title: 'Must Support $inquire Response Bundles',
          type: 'textarea',
          optional: true,
          description: DaVinciPASTestKit.ms_responses_input_description('$inquire')
    config options: { accepts_multiple_requests: true, submit_enabled: true, inquire_enabled: true }
    output :confirmation_url

    run do
      wait_identifier = session_wait_identifier(client_id, session_url_path)
      submit_endpoint = session_endpoint_url(:submit, client_id, session_url_path)
      inquire_endpoint = session_endpoint_url(:inquire, client_id, session_url_path)
      confirmation_url = "#{resume_pass_url}?token=#{wait_identifier}"
      output(confirmation_url:)

      wait(
        identifier: wait_identifier,
        message: <<~MESSAGE
          **Additional Must Support Demonstration**:

          Inferno will wait while the tester uses the system to make additional $submit and $inquire requests.
          Along with the requests submitted during previous tests, these requests and their responses must
          cumulatively demonstrate coverage of all required profiles and all must support elements within
          those profiles, as specified by the DaVinci Prior Authorization Support implementation guide.

          [Click here](#{confirmation_url}) when all requests have been submitted.

          ### Required Profiles

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

          ### Endpoints

          Submit a PAS requests to

          - $submit: `#{submit_endpoint}`
          - $inquire: `#{inquire_endpoint}`

          ### Authentication and Identification

          #{auth_description_for_wait(client_id)}

          ### Submit Responses

          #{response_description_for_wait(user_inputted_response?(:ms_submit_responses),
                                          input_title(:ms_submit_responses))}

          ### Inquire Resposnes

          #{response_description_for_wait(user_inputted_response?(:ms_inquire_responses),
                                          input_title(:ms_inquire_responses))}

        MESSAGE
      )
    end
  end
end
