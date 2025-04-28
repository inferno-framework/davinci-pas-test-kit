module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientReviewSubmitAttest < Inferno::Test
      include URLs

      id :pas_client_v201_review_submit_attest
      title 'Check that the client permits, not does not require, the provider to review prior auth data'
      description <<~DESCRIPTION
        This test provides the tester an opportunity to observer their client permitting, but not requiring, the provider to review prior authorization submission data prior to transmission.
      DESCRIPTION

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@11', 'hl7.fhir.us.davinci-pas_2.0.1@187',
                            'hl7.fhir.us.davinci-pas_2.0.1@188'

      def workflow_tag
        config.options[:workflow_tag]
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
          message: <<~MESSAGE
            **#{workflow_name} Workflow Test**:

            I attest that the client system permits, but does not require, the provider to review prior authorization submission data prior to transmission.

            [Click here](#{resume_pass_url}?token=#{identifier}) if the above statement is **true**.

            [Click here](#{resume_fail_url}?token=#{identifier}) if the above statement is **false**.
          MESSAGE
        )
      end
    end
  end
end
