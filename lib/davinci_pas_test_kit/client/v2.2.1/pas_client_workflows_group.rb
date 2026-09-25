require_relative 'pas_client_approval_group'
require_relative 'pas_client_denial_group'
require_relative 'pas_client_pended_group'
require_relative 'pas_client_claim_updates_group'
require_relative 'pas_client_modification_group'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientWorkflowsGroup < Inferno::TestGroup
      id :pas_client_v221_workflows
      title 'PAS Workflows'
      description %(
        The workflow tests verify that the client can participate in complete end-to-end prior
        authorization interactions, initiating requests and reacting appropriately to the
        responses returned.
      )

      input_order :approval_json_response,
                  :denial_json_response,
                  :pended_json_response,
                  :notification_bundle,
                  :client_endpoint_access_token,
                  :claim_update_initial_response,
                  :claim_update_add_item_response,
                  :claim_update_modify_cancel_response,
                  :claim_update_cancel_all_response,
                  :modification_json_response,
                  :client_id,
                  :session_url_path

      group from: :pas_client_v221_approval_group
      group from: :pas_client_v221_denial_group
      group from: :pas_client_v221_pended_group
      group from: :pas_client_v221_claim_updates_group
      group from: :pas_client_v221_modification_group
    end
  end
end
