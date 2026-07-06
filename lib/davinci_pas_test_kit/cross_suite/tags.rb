# frozen_string_literal: true

module DaVinciPASTestKit
  AUTH_TAG = 'pas_auth'
  SUBMIT_TAG = 'pas_submit'
  INQUIRE_TAG = 'pas_inquire'
  APPROVAL_WORKFLOW_TAG = 'pas_approved_workflow'
  DENIAL_WORKFLOW_TAG = 'pas_denied_workflow'
  PENDED_WORKFLOW_TAG = 'pas_pended_workflow'
  MODIFICATION_WORKFLOW_TAG = 'pas_modified_workflow'
  MUST_SUPPORT_WORKFLOW_TAG = 'pas_must_support_workflow'
  # Claim update workflow: a unique tag per submission so verification tests can
  # reload each specific request (initial submit, then each subsequent update).
  CLAIM_UPDATE_INITIAL_TAG = 'pas_claim_update_initial'
  CLAIM_UPDATE_ADD_ITEM_TAG = 'pas_claim_update_add_item'
  CLAIM_UPDATE_MODIFY_CANCEL_TAG = 'pas_claim_update_modify_cancel'
  CLAIM_UPDATE_CANCEL_ALL_TAG = 'pas_claim_update_cancel_all'
  NOTIFICATION_TAG = 'subscription_notification'
  SUBSCRIPTION_CREATE_TAG = 'subscription_create'
  SUBSCRIPTION_READ_TAG = 'subscription_read'
  SUBSCRIPTION_STATUS_TAG = 'subscription_status'
  REST_HOOK_HANDSHAKE_NOTIFICATION_TAG = 'rest_hook_handshake_notification'
  REST_HOOK_EVENT_NOTIFICATION_TAG = 'rest_hook_event_notification'
  OTHER_AUTH_TAG = 'other_auth'

  def self.use_case_tag(use_case)
    const_get(:"#{use_case.upcase}_WORKFLOW_TAG")
  end

  def self.operation_tag(operation)
    const_get(:"#{operation.upcase}_TAG")
  end
end
