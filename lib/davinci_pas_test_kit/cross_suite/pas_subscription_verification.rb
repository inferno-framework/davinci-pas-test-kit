module DaVinciPASTestKit
  module PASSubscriptionVerification
    PAS_SUBSCRIPTION_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-subscription'.freeze
    PAS_SUBSCRIPTION_TOPIC = 'http://hl7.org/fhir/us/davinci-pas/SubscriptionTopic/PASSubscriptionTopic'.freeze
    BACKPORT_FILTER_CRITERIA_URL =
      'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-filter-criteria'.freeze

    def verify_pas_subscription(subscription_json_str, ig_version: 'v2.0.1')
      assert_valid_json(subscription_json_str)
      subscription = JSON.parse(subscription_json_str)

      if ig_version == 'v2.0.1'
        verify_pas_subscription_v201(subscription)
      else
        verify_pas_subscription_v220(subscription)
      end

      assert messages.none? { |msg| msg[:type] == 'error' },
             'The Subscription does not conform to PAS requirements - see messages for details.'
    end

    private

    def verify_pas_subscription_v201(subscription)
      unless subscription['criteria'] == PAS_SUBSCRIPTION_TOPIC
        add_message('error', %(
          The Subscription must use the PAS-defined Subscription topic
          `#{PAS_SUBSCRIPTION_TOPIC}`
          in the `Subscription.criteria` element.
        ))
      end

      filter_criteria = subscription.dig('_criteria', 'extension')
        &.select { |ext| ext['url'] == BACKPORT_FILTER_CRITERIA_URL }
      return if filter_criteria&.length == 1

      add_message('error', %(
            The Subscription must include a single filter on the submitting organization
            in the `Subscription.criteria.extension` element.
          ))
    end

    def verify_pas_subscription_v220(subscription)
      verify_v220_profile(subscription)
      verify_v220_criteria_format(subscription)
    end

    def verify_v220_profile(subscription)
      resource = FHIR.from_contents(subscription.to_json)
      resource_is_valid?(resource: resource, profile_url: PAS_SUBSCRIPTION_PROFILE)
    end

    def verify_v220_criteria_format(subscription)
      filter_criteria = subscription.dig('_criteria', 'extension')
        &.select { |ext| ext['url'] == BACKPORT_FILTER_CRITERIA_URL }

      return if filter_criteria.blank?

      filter_criteria.each do |fc|
        value = fc['valueString']
        next if value.present? && value.match?(/\Aorg-identifier=\S+\z/)

        add_message('error', %(
          The Subscription filter criteria value `#{value}` does not match
          the expected format `org-identifier=<identifier>`.
        ))
      end
    end
  end
end
