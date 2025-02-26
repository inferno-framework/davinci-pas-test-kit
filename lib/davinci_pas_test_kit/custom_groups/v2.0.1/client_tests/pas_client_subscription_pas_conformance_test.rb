# frozen_string_literal: true

module DaVinciPASTestKit
  module DaVinciPASV201
    class SubscriptionPASConformanceTest < Inferno::Test
      id :pas_client_v201_subscription_pas_conformance_test
      title 'Client Subscription PAS Conformance Verification'
      description %(
        This test verifies that the Subscription created by the client under test
        is conformant to PAS requirements on the Subscription, including
        - The use of the [PAS-defined Subscription
          Topic](https://hl7.org/fhir/us/davinci-pas/STU2/SubscriptionTopic-PASSubscriptionTopic.html), and
        - Inclusion of filter criteria for the client's organization.
      )

      run do
        load_tagged_requests(SUBSCRIPTION_CREATE_TAG)
        skip_if(requests.none?, 'Inferno did not receive a Subscription creation request')
        subscription_resource = request.request_body

        assert_valid_json(subscription_resource)
        subscription = JSON.parse(subscription_resource)

        unless subscription['criteria'] == 'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'
          add_message('error', %(
            The created Subscription must use the PAS-defined Subscription topic
            `http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic`
            in the `Subscription.criteria` element.
          ))
        end

        filter_criteria = subscription.dig('_criteria', 'extension')
          &.select do |ext|
            ext['url'] == 'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-filter-criteria'
          end
        unless filter_criteria&.length == 1
          add_message('error', %(
            The created Subscription must include a single filter on the submitting organization
            in the `Subscription.criteria.extension` element.
          ))
        end

        assert messages.none? { |msg| msg[:type] == 'error' },
               'The Created Subscription does not conform to PAS requirements - see messages for details.'
      end
    end
  end
end
