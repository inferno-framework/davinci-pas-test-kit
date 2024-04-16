require_relative '../../../urls'
require_relative '../../../user_input_response'
require_relative '../../../pas_bundle_validation'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientDenialSubmitTest < Inferno::Test
      include URLs
      include UserInputResponse
      include PasBundleValidation

      id :pas_client_v201_denial_submit_test
      title 'Client submits a claim using the $submit operation'
      description %(
        Inferno will wait for a prior authorization submission request
        from the client. Upon receipt, Inferno will respond with the
        provided denial response.
      )
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )

      run do
        check_user_inputted_response :denial_json_response
        wait(
          identifier: access_token,
          message: %(
            **Denial Workflow Test**:

            Submit a PAS request to

            `#{submit_url}`

            The denial response provided in the '**#{input_title(:denial_json_response)}**' input will be returned.
          )
        )
      end
    end
  end
end
