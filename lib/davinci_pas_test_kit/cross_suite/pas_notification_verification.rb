require_relative 'tags'

module DaVinciPASTestKit
  module PASNotificationVerification
    PAS_RESPONSE_BUNDLE_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle'.freeze

    def verify_pas_notification(notification_json_str, ig_version: 'v2.2.0') # rubocop:disable Lint/UnusedMethodArgument
      assert_valid_json(notification_json_str)
      notification_bundle = FHIR.from_contents(notification_json_str)

      assert notification_bundle.present?, 'Not a FHIR resource'
      assert_resource_type(:bundle, resource: notification_bundle)

      assert notification_bundle.entry.present?,
             'The notification Bundle must contain at least one entry'

      # First entry is the SubscriptionStatus Parameters resource
      subscription_status = notification_bundle.entry[0]&.resource
      assert subscription_status&.resourceType == 'Parameters',
             'The first entry in the notification Bundle must be a Parameters ' \
             "(SubscriptionStatus) resource, but found `#{subscription_status&.resourceType}`"

      # Extract focus references from notification-event parameters
      focus_references = extract_focus_references(subscription_status)
      assert focus_references.present?,
             'The SubscriptionStatus must include at least one notification-event ' \
             'parameter with a focus reference'

      # Resolve each focus reference to a Bundle entry and validate PAS structure
      bundle_entries = notification_bundle.entry.drop(1)
      focus_references.each do |focus_ref|
        focus_entry = resolve_focus_entry(focus_ref, bundle_entries)

        if focus_entry.nil?
          add_message('error', %(
            Could not resolve focus reference `#{focus_ref}` to a Bundle entry.
            The notification Bundle must include the focus resource.
          ))
          next
        end

        focus_resource = focus_entry.resource
        if focus_resource.nil?
          add_message('error', %(
            The Bundle entry for focus reference `#{focus_ref}` does not contain
            a resource.
          ))
          next
        end

        # Check PAS-specific structural requirements only.
        # Profile validation is handled by the Subscription conformance tests
        # (9.3.3.01 and 9.3.3.02) to avoid duplicate error messages.
        validate_focus_as_response_bundle(focus_resource)
      end

      assert messages.none? { |msg| msg[:type] == 'error' },
             'The notification does not conform to PAS requirements - see messages for details.'
    end

    private

    def extract_focus_references(subscription_status)
      return [] unless subscription_status.respond_to?(:parameter)

      notification_events = subscription_status.parameter&.select do |p|
        p.name == 'notification-event'
      end
      return [] if notification_events.blank?

      notification_events.filter_map do |event|
        focus_part = event.part&.find { |part| part.name == 'focus' }
        focus_part&.valueReference&.reference
      end
    end

    def resolve_focus_entry(reference, bundle_entries)
      check_full_url = reference.start_with?('urn:')

      bundle_entries.find do |entry|
        if check_full_url
          reference == entry.fullUrl
        else
          entry.fullUrl == reference ||
            (entry.resource.present? &&
             reference.include?("#{entry.resource.resourceType}/#{entry.resource.id}"))
        end
      end
    end

    # Validates PAS-specific structural requirements only:
    # - Focus resource must be a Bundle
    # - Bundle must be of type 'collection' (PAS Response Bundle)
    # - Bundle must contain at least one ClaimResponse entry
    def validate_focus_as_response_bundle(focus_resource)
      if focus_resource.resourceType != 'Bundle'
        add_message('error', %(
          Expected the focus resource to be a Bundle (PAS Response Bundle),
          but found `#{focus_resource.resourceType}`.
        ))
        return
      end

      if focus_resource.type != 'collection'
        add_message('error', %(
          Expected the focus Bundle to be of type 'collection' (PAS Response Bundle),
          but found type '#{focus_resource.type}'.
        ))
      end

      claim_response = focus_resource.entry&.find { |e| e.resource&.resourceType == 'ClaimResponse' }
      return if claim_response.present?

      add_message('error', %(
        The focus Bundle (PAS Response Bundle) must contain at least one
        ClaimResponse entry, but none was found.
      ))
    end
  end
end
