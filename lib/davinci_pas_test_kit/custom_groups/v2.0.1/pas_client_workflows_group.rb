require_relative 'pas_client_approval_group'
require_relative 'pas_client_denial_group'
require_relative 'pas_client_pended_group'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientWorkflowsGroup < Inferno::TestGroup
      id :pas_client_v201_workflows
      title 'PAS Workflows'
      description %(
        The workflow tests verify that the client can participate in complete end-to-end prior
        authorization interactions, initiating requests and reacting appropriately to the
        responses returned.
      )

      group from: :pas_client_v201_approval_group
      group from: :pas_client_v201_denial_group
      group from: :pas_client_v201_pended_group
    end
  end
end
