require_relative '../generated/v2.0.1/pas_client_submit_must_support_group'
require_relative '../generated/v2.0.1/pas_client_inquire_must_support_group'
require_relative '../generated/v2.0.1/pas_client_submit_response_must_support_group'
require_relative '../generated/v2.0.1/pas_client_inquire_response_must_support_group'
require_relative 'must_support/pas_client_gather_must_support_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_request_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_response_bundle_validation_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientMustSupportGroup < Inferno::TestGroup
      id :pas_client_v201_must_support
      title 'Must Support Elements'
      run_as_group
      description %(
        During these tests, Inferno will check that the client system demonstrates support for
        all required profiles and must support elements. When looking for demonstration of
        these profiles and elements, Inferno will consider requests and responses from
        interactions performed during the PAS scenario group as well as additional ones
        made when executing this group.

        For additional details on these tests, what they check for, and the requirements
        underlying them, see the ["Client Must Support Tests" section](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support)
        of the Da Vinci PAS Test Kit wiki, specifically
        - [Which messages Inferno considers when looking for demonstration of must support elements](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support#evaluated-messages).
        - [What clients must demonstrate to pass these v2.2.1 client must support tests](https://github.com/inferno-framework/davinci-pas-test-kit/wiki/Client-Must-Support#da-vinci-pas-v2-0-1).
      )

      # The must support response inputs already belong to pas_client_v201_gather_must_support
      # (the wait test below); declaring them here too, before it and the Bundle Conformance
      # groups further down are defined, propagates them onto the bundle validation test slots
      # in those groups as well, so they can tell whether a tester-provided response was used
      # - see PasClientResponseBundleValidationTest/PasClientInquireResponseBundleValidationTest
      # #failed_entities_description.
      input :ms_submit_responses, optional: true
      input :ms_inquire_responses, optional: true

      input_order :ms_submit_responses,
                  :ms_inquire_responses,
                  :client_id,
                  :session_url_path

      # Combined receive group - single wait test for both submit and inquire
      group do
        id :pas_client_v201_must_support_receive
        title 'Demonstrate Must Support Coverage'
        description %(
          During this group, Inferno will wait while the tester uses the client system to
          make `$submit` and `$inquire` operation requests to Inferno demonstrating coverage
          of must support elements not yet demonstrated.

          Inferno then asks for confirmation that all responses were handled
          without error and verifies the conformance of all requests and responses.
        )
        run_as_group

        test from: :pas_client_v201_gather_must_support
        test from: :pas_client_v201_response_attest,
             id: :pas_client_v201_response_attest_ms_submit_inquire,
             title: 'PAS client handled the $submit and $inquire responses without erroring',
             description: %(
               During this test, the tester will verify that the client handled
               the `$submit` and `$inquire` operation responses, making the result available to
               the user without failing or erroring.
             ),
             config: { options: {
               workflow_tag: MUST_SUPPORT_WORKFLOW_TAG,
               no_requests_ok: true,
               multiple_requests_ok: true,
               attest_message: 'I attest that the client system correctly handled the `$submit` and `$inquire` ' \
                               'operation responses received from Inferno during this test, making the details ' \
                               'available to users without errors.'
             } } do
          verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@41'
        end

        test from: :pas_client_v201_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
        test from: :pas_client_v201_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
        test from: :pas_client_v201_inquire_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
        test from: :pas_client_v201_inquire_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
      end

      # $submit Request Must Support (fail when errors detected)
      group from: :pas_client_v201_submit_must_support

      # $submit Response Must Support (skip when errors detected)
      group from: :pas_client_v201_submit_response_must_support

      # $inquire Request Must Support (fail when errors detected)
      group from: :pas_client_v201_inquire_must_support

      # $inquire Response Must Support (skip when errors detected)
      group from: :pas_client_v201_inquire_response_must_support
    end
  end
end
