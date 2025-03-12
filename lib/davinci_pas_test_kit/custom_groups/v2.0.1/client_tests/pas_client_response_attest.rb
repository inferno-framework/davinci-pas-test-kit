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
        identifier = SecureRandom.hex(32)
        wait(
          identifier:,
          message: %(
            **#{workflow_name} Workflow Test**:

            #{attest_message}

            [Click here](#{resume_pass_url}?token=#{identifier}) if the above statement is **true**.

            [Click here](#{resume_fail_url}?token=#{identifier}) if the above statement is **false**.
          )
        )
      end
    end
  end
end
