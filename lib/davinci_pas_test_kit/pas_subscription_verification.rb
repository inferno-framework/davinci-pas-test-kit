module DaVinciPASTestKit
  module PASSubscriptionVerification
    def verify_pas_subscription(subscription_json_str)
      assert_valid_json(subscription_json_str)
      subscription = JSON.parse(subscription_json_str)

      unless subscription['criteria'] == 'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'
        add_message('error', %(
          The Subscription must use the PAS-defined Subscription topic
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
            The Subscription must include a single filter on the submitting organization
            in the `Subscription.criteria.extension` element.
          ))
      end

      assert messages.none? { |msg| msg[:type] == 'error' },
             'The Subscription does not conform to PAS requirements - see messages for details.'
    end
  end
end
