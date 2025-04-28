module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientCancellationGroup < Inferno::TestGroup
      # include UserInputResponse ?
      id :pas_client_v201_cancellation_group
      title 'Cancellation Workflow'
      description %(
        During these tests, the client will initiate a prior authorization
        request and show it can respond appropriately to a 'canceled' decision
      )
      run_as_group

      input :cancellation_json_response, optional: true

      input_order :cancellation_json_response,
                  :client_id,
                  :session_url_path
    end
  end
end
