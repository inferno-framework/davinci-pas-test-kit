# frozen_string_literal: true

require 'subscriptions_test_kit'
require_relative '../../../cross_suite/pas_subscription_verification'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PASClientSubscriptionPutUpdatePASConformanceTest < Inferno::Test
      include SubscriptionsTestKit::SubscriptionsR5BackportR4Client::UpdateRequestLoading
      include PASSubscriptionVerification

      id :pas_client_v221_subscription_put_update_pas_conformance_test
      title 'Subscription update requests meet PAS Subscription requirements'
      description %(
        This test verifies that the Subscriptions in the accepted [update](https://hl7.org/fhir/R4/http.html#update)
        (`PUT`) requests that the client under test sent to Inferno for the Subscription it created during this
        session are conformant to PAS requirements on the Subscription, including
        - Conformance to the [PAS Subscription
          profile](https://hl7.org/fhir/us/davinci-pas/2.2.1/StructureDefinition-profile-subscription.html), and
        - Filter criteria for the client's organization in the format `org-identifier=<identifier>`.
      )

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-62'

      run do
        load_update_requests('put')

        # Numbered among all PUT requests so that messages line up with the general update conformance test
        accepted_requests = requests.each.with_index(1).select { |update_request, _| update_request.status == 200 }
        skip_if accepted_requests.none?, %(
          Inferno did not accept any PUT update requests for the created Subscription, so there are no updated
          Subscriptions to check.
        )

        accepted_requests.each do |update_request, request_number|
          first_message_index = messages.length
          add_pas_subscription_messages(JSON.parse(update_request.request_body), ig_version: 'v2.2.1')
          messages[first_message_index..].each do |message|
            message[:message] = "Request #{request_number}: #{message[:message]}"
          end
        end

        assert messages.none? { |message| message[:type] == 'error' },
               'Subscription PUT update requests do not conform to PAS requirements - see messages for details.'
      end
    end
  end
end
