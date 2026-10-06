require_relative '../generated/v2.0.1/pas_client_submit_must_support_group'
require_relative '../generated/v2.0.1/pas_client_inquire_must_support_group'
require_relative '../generated/v2.0.1/pas_client_submit_response_must_support_group'
require_relative '../generated/v2.0.1/pas_client_inquire_response_must_support_group'
require_relative 'must_support/pas_client_gather_must_support_test'
require_relative 'workflows/pas_client_request_bundle_validation_test'
require_relative 'workflows/pas_client_response_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_request_bundle_validation_test'
require_relative 'workflows/pas_client_inquire_response_bundle_validation_test'
require_relative '../client_input_descriptions'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientMustSupportGroup < Inferno::TestGroup
      id :pas_client_v201_must_support
      title 'Must Support Elements'
      run_as_group
      description DaVinciPASTestKit.must_support_group_description('v2.0.1', 'da-vinci-pas-v201')

      # The must support response inputs already belong to pas_client_v201_gather_must_support
      # (the wait test below); declaring them here too, before the receive group is defined,
      # propagates them onto the bundle validation tests in that group as well, so they can tell
      # whether a tester-provided response was used - see
      # PasClientResponseBundleValidationTest/PasClientInquireResponseBundleValidationTest
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
        title MUST_SUPPORT_RECEIVE_GROUP_TITLE
        description MUST_SUPPORT_RECEIVE_GROUP_DESCRIPTION
        run_as_group

        test from: :pas_client_v201_gather_must_support
        test from: :pas_client_v201_response_attest,
             id: :pas_client_v201_response_attest_ms_submit_inquire,
             title: MUST_SUPPORT_SUBMIT_INQUIRE_ATTEST_TITLE,
             description: MUST_SUPPORT_SUBMIT_INQUIRE_ATTEST_DESCRIPTION,
             config: { options: {
               workflow_tag: MUST_SUPPORT_WORKFLOW_TAG,
               no_requests_ok: true,
               multiple_requests_ok: true,
               attest_message: MUST_SUPPORT_SUBMIT_INQUIRE_ATTEST_MESSAGE
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
