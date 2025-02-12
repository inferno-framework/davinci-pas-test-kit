require_relative '../../../urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientResponseAttest < Inferno::Test
      include URLs

      id :pas_client_v201_response_attest
      title 'Check that the client reacts appropriately to the response (Attestation)'
      description %(
        This test provides the tester an opportunity to observe their client following
        the receipt of response and attest that users are able to see the appropriate
        updates to the corresponding prior authorization request in their system.
      )
      input :access_token,
            title: 'Access Token',
            description: %(
              Access token that the client will provide in the Authorization header of each request
              made during this test.
            )

      def workflow_tag
        config.options[:workflow_tag]
      end

      def attest_message
        config.options[:attest_message]
      end

      def workflow_name
        case workflow_tag
        when APPROVAL_WORKFLOW_TAG
          'Approval'
        when DENIAL_WORKFLOW_TAG
          'Denial'
        when PENDED_WORKFLOW_TAG
          'Pended'
        end
      end

      run do
        wait(
          identifier: access_token,
          message: %(
            **#{workflow_name} Workflow Test**:

            #{attest_message}

            [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

            [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
          )
        )
      end
    end
  end
end
