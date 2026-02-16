require_relative 'tags'

module DaVinciPASTestKit
  module PASNotificationVerification
    PAS_RESPONSE_BUNDLE_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle'

    def verify_pas_notification(notification_json_str)
      assert_valid_json(notification_json_str)
      notification = JSON.parse(notification_json_str)

      assert notification['resourceType'] == 'Bundle',
             "Expected notification to be a Bundle, but found `#{notification['resourceType']}`"

      # The first entry should be a Parameters (SubscriptionStatus), remaining entries are focus resources
      focus_entries = (notification['entry'] || [])[1..]
      if focus_entries.blank?
        add_message('error', %(
          The notification Bundle must include at least one focus resource entry
          beyond the SubscriptionStatus Parameters resource.
        ))
      else
        # Check that at least one focus entry references a PAS Response Bundle profile
        has_pas_response = focus_entries.any? do |entry|
          resource = entry['resource']
          next false unless resource

          resource_profiles = resource.dig('meta', 'profile') || []
          resource_profiles.any? { |p| p.start_with?(PAS_RESPONSE_BUNDLE_PROFILE) }
        end

        unless has_pas_response
          add_message('warning', %(
            None of the focus resources in the notification Bundle declare conformance
            to the PAS Response Bundle profile
            `#{PAS_RESPONSE_BUNDLE_PROFILE}`.
            For PAS notifications, the focus resource should be the updated ClaimResponse
            included in a PAS Response Bundle.
          ))
        end
      end

      assert messages.none? { |msg| msg[:type] == 'error' },
             'The notification does not conform to PAS requirements - see messages for details.'
    end
  end
end
