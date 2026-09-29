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
        During these tests, Inferno will check that the client system demonstrates support for
        all required profiles and elements. PAS requires that clients:

        - [Follow](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformance.html#mustsupport) the
          [must support requirements for data sources defined in HRex](https://hl7.org/fhir/us/davinci-hrex/1.2.0/en/conformance.html#mustsupport)
          and make prior authorization `$submit` and `$inquire` operation requests that contain all
          PAS-defined profiles and their must support elements.
        - Be able to [receive](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformance.html#ci-c-conf-7),
          [without error](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformance.html#ci-c-conf-8),
          all must support elements defined on the PAS ClaimResponse profiles.

        To pass these tests, Inferno must see
        - On Requests
          - All must support elements defined on the [PAS Claim](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claim.html)
            or [PAS Claim Update](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claim-update.html)
            profiles on `$submit` requests, or the [PAS Claim Inquiry](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claim-inquiry.html)
            profile on `$inquire` requests.
          - For `$submit` requests, at least one instance of one of the request resource profiles ([DeviceRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-devicerequest.html),
            [MedicationRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-medicationrequest.html),
            [NutritionOrder](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-nutritionorder.html),
            or [ServiceRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-servicerequest.html))
            referenced from the [Requested Service extension](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-extension-requestedService.html)
            on element `Claim.item`, and all must support elements defined in the profiles for each
            request resource type that was observed. Testers may attest that such elements not observed
            are not supported by their system and pass the test.
          - For both `$submit` and `$inquire` requests, at least one instance of each other profile referenced from the PAS Claim profiles and
            all must support elements defined on those profiles. Testers may attest that such
            elements not observed are not supported by their system and pass the test. Specific
            profiles for which must support coverage must be demonstrated include:
            - [PAS Coverage](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-coverage.html)
            - [PAS Encounter](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-encounter.html)
            - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-insurer.html)
            - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-requestor.html)
            - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-beneficiary.html)
            - [PAS Subscriber Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-subscriber.html)
            - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitioner.html)
            - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitionerrole.html)
        - On Responses
          - All must support elements defined on the [PAS Claim Response](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claimresponse.html)
            or [PAS Claim Inquiry Response](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-claiminquiryresponse.html)
            profiles for `$submit` and `$inquire` requests respectively.
          - Optionally, for both `$submit` and `$inquire` requests, at least one instance of each
            other profile referenced from the PAS ClaimResponse profiles and all must support
            elements defined on those profiles. Specific profiles for which must support coverage
            must be demonstrated include:
            - [PAS CommunicationRequest](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-communicationrequest.html)
              (`$submit` responses only)
            - [PAS Insurer Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-insurer.html)
            - [PAS Requestor Organization](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-requestor.html)
            - [PAS Beneficiary Patient](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-beneficiary.html)
            - [PAS Practitioner](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitioner.html)
            - [PAS PractitionerRole](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-practitionerrole.html)
            - [PAS Task](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/StructureDefinition-profile-task.html)

        Inferno will consider `$submit` requests and responses made on the most recent execution of
        each previously-executed group. When any group is re-run, including this one, the requests made
        during the previous run of that group will no longer be considered.

        As a part of executing this group, Inferno will wait for additional requests to be made, including
        additional `$submit` requests covering must support elements not yet demonstrated and
        `$inquire` requests which are not part of, or supported by Inferno during, any of the
        prior workflow groups. Note that Inferno's mocked responses do not include all must support
        elements, so testers will need to provide responses for Inferno to use that include
        examples of all must support elements to pass these tests.
      )

      # The must support response inputs already belong to pas_client_v221_gather_must_support
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
        id :pas_client_v221_must_support_receive
        title 'Demonstrate Must Support Coverage'
        description %(
          During this group, Inferno will wait while the tester uses the client system to
          make `$submit` and `$inquire` operation requests to Inferno demonstrating coverage
          of must support elements not yet demonstrated.

          Inferno then asks for confirmation that all responses were handled
          without error and verifies the conformance of all requests and responses.
        )
        run_as_group

        test from: :pas_client_v221_gather_must_support
        test from: :pas_client_v221_response_attest,
             id: :pas_client_v221_response_attest_ms_submit_inquire,
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
          verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@conf-8'
        end

        test from: :pas_client_v221_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
        test from: :pas_client_v221_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
        test from: :pas_client_v221_inquire_request_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
        test from: :pas_client_v221_inquire_response_bundle_validation_test,
             config: { options: { workflow_tag: MUST_SUPPORT_WORKFLOW_TAG, no_requests_ok: true,
                                  multiple_requests_ok: true } }
      end

      # $submit Request Must Support (fail when errors detected)
      group from: :pas_client_v221_submit_must_support

      # $submit Response Must Support (skip when errors detected)
      group from: :pas_client_v221_submit_response_must_support

      # $inquire Request Must Support (fail when errors detected)
      group from: :pas_client_v221_inquire_must_support

      # $inquire Response Must Support (skip when errors detected)
      group from: :pas_client_v221_inquire_response_must_support
    end
  end
end
