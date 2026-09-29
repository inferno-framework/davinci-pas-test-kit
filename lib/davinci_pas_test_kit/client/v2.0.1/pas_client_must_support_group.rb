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
        all PAS-defined profiles and the must support elements defined in them. This includes:

        - The ability to make prior authorization `$submit` and `$inquire` operation requests that
          contain all PAS-defined profiles and their must support elements.
        - The ability to receive in responses to those requests all PAS-defined profiles and their
          must support elements.

        The tester will be able to use the client system to make additional requests to Inferno
        demonstrating coverage of all must support items in the requests and responses. Because
        Inferno's mocked responses do not include all must support elements, testers will need
        to provide responses that include examples of all must support elements so that they can
        demonstrate the client system's support for those elements.

        Note that Inferno will consider requests made during the workflow group of tests, so only
        profiles and must support elements not demonstrated during those earlier tests need to be
        submitted as a part of these. However, Inferno will only consider requests made during the
        most recent run of a given test. Therefore, if additional runs of this group, or others,
        are needed, any elements only demonstrated in the prior run must be demonstrated again to
        count.
      )

      # The must support response inputs already belong to pas_client_v201_gather_must_support
      # (the wait test below); declaring them here too, before it and the Bundle Conformance
      # groups further down are defined, propagates them onto the bundle validation test slots
      # in those groups as well, so they can tell whether a tester-provided response was used
      # - see PasClientResponseBundleValidationTest/PasClientInquireResponseBundleValidationTest
      # #failed_entities_description.
      input :ms_submit_responses, optional: true
      input :ms_inquire_responses, optional: true

      # Combined receive group - single wait test for both submit and inquire
      group do
        id :pas_client_v201_must_support_receive
        title 'Demonstrate Must Support Coverage'
        description %(
          During this group, Inferno will wait while the tester uses the client system to
          make `$submit` and `$inquire` operation requests to Inferno demonstrating coverage
          of must support elements not yet demonstrated.
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
             } }
      end

      # $submit Bundle Conformance Validation
      group do
        title '$submit Bundle Conformance'
        description %(
          During this group, Inferno will verify that the `$submit` request bundles sent by
          the client are conformant and that the $submit response bundles provided for Inferno
          to send back are conformant.
        )
        run_as_group

        test from: :pas_client_v201_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, multiple_requests_ok: true } }
        test from: :pas_client_v201_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, multiple_requests_ok: true } }
      end

      # $submit Request Must Support (fail when errors detected)
      group from: :pas_client_v201_submit_must_support

      # $submit Response Must Support (skip when errors detected)
      group from: :pas_client_v201_submit_response_must_support

      # $inquire Bundle Conformance Validation
      group do
        title '$inquire Bundle Conformance'
        description %(
          During this group, Inferno will verify that the `$inquire` request bundles sent by
          the client are conformant and that the $inquire response bundles provided for Inferno
          to send back are conformant.
        )
        run_as_group

        test from: :pas_client_v201_inquire_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, multiple_requests_ok: true } }
        test from: :pas_client_v201_inquire_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, multiple_requests_ok: true } }
      end

      # $inquire Request Must Support (fail when errors detected)
      group from: :pas_client_v201_inquire_must_support

      # $inquire Response Must Support (skip when errors detected)
      group from: :pas_client_v201_inquire_response_must_support
    end
  end
end
