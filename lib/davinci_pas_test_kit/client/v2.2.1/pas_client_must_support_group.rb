require_relative '../generated/v2.2.1/pas_client_submit_must_support_group'
require_relative '../generated/v2.2.1/pas_client_inquire_must_support_group'
require_relative '../generated/v2.2.1/pas_client_submit_response_must_support_group'
require_relative '../generated/v2.2.1/pas_client_inquire_response_must_support_group'
require_relative 'must_support/pas_client_gather_must_support_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_request_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_response_bundle_validation_test'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientMustSupportGroup < Inferno::TestGroup
      id :pas_client_v221_must_support
      title 'Must Support Elements'
      run_as_group
      description %(
        During these tests, the client will show that it supports all PAS-defined profiles and the must support
        elements defined in them. This includes

        - The ability to make prior authorization submission and inquiry requests that contain all
          PAS-defined profiles and their must support elements.
        - The ability to receive in responses to those requests all PAS-defined profiles and their
          must support elements.

        Clients under test will be asked to make additional requests to Inferno demonstrating coverage
        of all must support items in the requests. Clients must also demonstrate that they can handle
        all response must support elements. Because Inferno's mocked responses do not include all must
        support elements, testers will need to provide responses that include examples of all must
        support elements for Inferno to respond with.

        Note that Inferno will consider requests made during the workflow group of tests, so only
        profiles and must support elements not demonstrated during those tests need to be submitted
        as a part of these.
      )

      # Combined receive group - single wait test for both submit and inquire
      group do
        id :pas_client_v221_must_support_receive
        title 'Demonstrate Must Support Coverage'
        description %(
          Submit $submit and $inquire requests demonstrating coverage of must support elements.
          Optionally, provide response bundles for Inferno to use when responding. Inferno will
          verify both the requests received and the responses provided.
        )
        run_as_group

        test from: :pas_client_v221_gather_must_support
      end

      # $submit Bundle Conformance Validation
      group do
        title '$submit Bundle Conformance'
        description %(
          Verify that the $submit request bundles sent by the client are conformant
          and that the $submit response bundles provided for Inferno to send back
          are conformant.
        )
        run_as_group

        test from: :pas_client_v221_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG } }
        test from: :pas_client_v221_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG } }
      end

      # $submit Request Must Support (fail when errors detected)
      group from: :pas_client_v221_submit_must_support

      # $submit Response Must Support (skip when errors detected)
      group from: :pas_client_v221_submit_response_must_support

      # $inquire Bundle Conformance Validation
      group do
        title '$inquire Bundle Conformance'
        description %(
          Verify that the $inquire request bundles sent by the client are conformant
          and that the $inquire response bundles provided for Inferno to send back
          are conformant.
        )
        run_as_group

        test from: :pas_client_v221_inquire_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG } }
        test from: :pas_client_v221_inquire_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG } }
      end

      # $inquire Request Must Support (fail when errors detected)
      group from: :pas_client_v221_inquire_must_support

      # $inquire Response Must Support (skip when errors detected)
      group from: :pas_client_v221_inquire_response_must_support
    end
  end
end
