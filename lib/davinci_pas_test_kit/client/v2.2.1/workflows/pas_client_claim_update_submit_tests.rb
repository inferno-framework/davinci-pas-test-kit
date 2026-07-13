require_relative '../urls'
require_relative '../../client_input_descriptions'
require_relative '../../user_input_response'
require_relative '../../session_identification'
require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    # Shared behavior for the Claim Update "wait" tests. Each subclass waits for a
    # single `$submit` request from the client and, on receipt, returns the response
    # configured through its dedicated response input (or an Inferno-generated approval
    # if none was provided). Subclasses differ only in:
    #   - their dedicated response input + `submit_respond_with`
    #   - the unique `claim_update_tag` used to tag the received request
    #   - the instructions shown to the tester (`interaction_instructions`)
    #
    # These tests auto-continue when a request is received (they do not set
    # `accepts_multiple_requests`, so `ClaimEndpoint#update_result` marks the result
    # `pass` and resumes the wait), and they never trigger a Subscription notification
    # (`suppress_notifications` is honored by `ClaimEndpoint#make_response`), even when
    # the configured response indicates the request was pended.
    class AbstractClaimUpdateSubmitTest < Inferno::Test
      include URLs
      include SessionIdentification
      include UserInputResponse

      id :pas_client_v221_claim_update_submit_base

      config options: { suppress_notifications: true }

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

      run do
        response_input = config.options[:submit_respond_with]
        if response_input.present? && send(response_input).present?
          assert_valid_json send(response_input),
                            "Input '#{input_title(response_input)}' must be valid JSON"
        elsif response_input.present?
          add_message('info', %(
            No response provided in input '#{input_title(response_input)}'. Inferno will generate an
            approved response to the $submit request from the submitted Claim.
          ))
        end

        wait_identifier = session_wait_identifier(client_id, session_url_path)
        submit_endpoint = session_endpoint_url(:submit, client_id, session_url_path)

        wait(
          identifier: wait_identifier,
          timeout: 600,
          message: claim_update_wait_message(submit_endpoint)
        )
      end

      def claim_update_wait_message(submit_endpoint)
        %(
          **Claim Update Workflow**

          #{interaction_instructions}

          Submit the request to

          `#{submit_endpoint}`

          #{response_note}

          Inferno will automatically continue once it receives the request, so no further
          action is required after submitting.
        )
      end

      def response_note
        response_input = config.options[:submit_respond_with]
        if response_input.present? && send(response_input).present?
          "The response provided in the '**#{input_title(response_input)}**' input will be returned, " \
            'updated with current timestamps.'
        else
          'Inferno will generate an approved response from the submitted Claim and return it.'
        end
      end

      # Overridden by subclasses to describe the specific submission the tester should make.
      def interaction_instructions
        raise NotImplementedError, "#{self.class} must implement #interaction_instructions"
      end
    end

    # Step 1: the initial prior authorization submission that subsequent updates build on.
    class PASClientClaimUpdateInitialSubmitTest < AbstractClaimUpdateSubmitTest
      id :pas_client_v221_claim_update_initial_submit_test
      title 'PAS client submits an initial prior authorization request'
      description %(
        Inferno waits for an initial prior authorization `$submit` request from the client.
        This establishes the original Claim that the subsequent updates will reference and
        modify. Upon receipt, Inferno returns the configured response (or generates an
        approved response from the submitted Claim) and continues automatically.
      )

      input :claim_update_initial_response,
            title: 'Initial claim response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be returned in response to the initial `$submit` request,
              updated with current timestamps. If not provided, an approved response will be generated
              from the submitted Claim.
            )

      submit_respond_with :claim_update_initial_response
      config options: { claim_update_tag: CLAIM_UPDATE_INITIAL_TAG }

      def interaction_instructions
        'Submit an **initial** prior authorization request (a `$submit` containing a Claim with one ' \
          'or more items and no `Claim.related.claim`).'
      end
    end

    # Step 2: an update that adds a new item to the previously submitted Claim.
    class PASClientClaimUpdateAddItemSubmitTest < AbstractClaimUpdateSubmitTest
      id :pas_client_v221_claim_update_add_item_submit_test
      title 'PAS client submits an update that adds an item'
      description %(
        Inferno waits for an updated prior authorization `$submit` request that adds a new item to
        the previously submitted Claim. The update is expected to reference the original Claim in
        `Claim.related.claim` (and include it in the Bundle), retain all previously submitted item
        and supportingInfo entries with their `sequence` values, and mark the newly added item with
        an `infoChanged` extension. Upon receipt, Inferno returns the configured response and
        continues automatically.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-63'

      input :claim_update_add_item_response,
            title: 'Add-item update response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be returned in response to the add-item update `$submit`
              request, updated with current timestamps. If not provided, an approved response will be
              generated from the submitted Claim.
            )

      submit_respond_with :claim_update_add_item_response
      config options: { claim_update_tag: CLAIM_UPDATE_ADD_ITEM_TAG }

      def interaction_instructions
        'Submit an **update that adds a new item** to the prior authorization. Reference the ' \
          'previously submitted Claim in `Claim.related.claim` and include that Claim in the Bundle, ' \
          'retain all previously submitted items and supportingInfo (preserving their `sequence` ' \
          'values), and mark the newly added item with an `infoChanged` extension.'
      end
    end

    # Step 3: an update that modifies one item and cancels another.
    class PASClientClaimUpdateModifyCancelSubmitTest < AbstractClaimUpdateSubmitTest
      id :pas_client_v221_claim_update_modify_cancel_submit_test
      title 'PAS client submits an update that modifies an item and cancels an item'
      description %(
        Inferno waits for a second updated prior authorization `$submit` request that modifies one
        existing item and cancels another. Modified entries are expected to carry an `infoChanged`
        extension; the canceled item is expected to carry the `infoCancelled` modifier extension
        (valueBoolean `true`), a `certificationType` extension with code `3` (Cancel) in
        `Claim.item.extension`, and an `infoChanged` extension. All prior item and supportingInfo
        entries are expected to be retained with preserved `sequence` values, referencing the
        immediately prior Claim update. Upon receipt, Inferno returns the configured response and
        continues automatically.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-63'

      input :claim_update_modify_cancel_response,
            title: 'Modify-and-cancel update response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be returned in response to the modify-and-cancel update
              `$submit` request, updated with current timestamps. If not provided, an approved response
              will be generated from the submitted Claim.
            )

      submit_respond_with :claim_update_modify_cancel_response
      config options: { claim_update_tag: CLAIM_UPDATE_MODIFY_CANCEL_TAG }

      def interaction_instructions
        'Submit an **update that modifies one item and cancels another**. Mark the modified item ' \
          'with an `infoChanged` extension. Mark the canceled item with the `infoCancelled` modifier ' \
          'extension (valueBoolean `true`), a `certificationType` extension with code `3` (Cancel) in ' \
          '`Claim.item.extension`, and an `infoChanged` extension. Retain all prior items and ' \
          'supportingInfo (preserving their `sequence` values) and reference the immediately prior ' \
          'Claim update in `Claim.related.claim`.'
      end
    end

    # Step 4: an update that cancels the entire prior authorization request.
    class PASClientClaimUpdateCancelAllSubmitTest < AbstractClaimUpdateSubmitTest
      id :pas_client_v221_claim_update_cancel_all_submit_test
      title 'PAS client submits an update that cancels the entire request'
      description %(
        Inferno waits for a third updated prior authorization `$submit` request that cancels the
        entire prior authorization. The update is expected to include a `certificationType` extension
        with code `3` (Cancel) in `Claim.extension`; no items are required to cancel the entire
        authorization. The update is expected to reference the immediately prior Claim update in
        `Claim.related.claim`. Upon receipt, Inferno returns the configured response and continues
        automatically.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-63'

      input :claim_update_cancel_all_response,
            title: 'Cancel-entire-request update response JSON',
            type: 'textarea',
            optional: true,
            description: %(
              If provided, this JSON will be returned in response to the cancel-entire-request update
              `$submit` request, updated with current timestamps. If not provided, an approved response
              will be generated from the submitted Claim.
            )

      submit_respond_with :claim_update_cancel_all_response
      config options: { claim_update_tag: CLAIM_UPDATE_CANCEL_ALL_TAG }

      def interaction_instructions
        'Submit an **update that cancels the entire prior authorization**. Include a ' \
          '`certificationType` extension with code `3` (Cancel) in `Claim.extension`; no items are ' \
          'required to cancel the entire authorization. Reference the immediately prior Claim update ' \
          'in `Claim.related.claim`.'
      end
    end
  end
end
