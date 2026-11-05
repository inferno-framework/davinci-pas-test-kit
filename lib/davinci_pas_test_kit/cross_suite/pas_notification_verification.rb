require_relative 'tags'

module DaVinciPASTestKit
  module PASNotificationVerification
    PAS_RESPONSE_BUNDLE_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle'.freeze
    # Notifications carrying the PAS Response Bundle are only tested for PAS v2.2.1
    PAS_NOTIFICATION_IG_VERSION = 'v2.2.1'.freeze

    # @param focus_validator [Symbol, nil] when given, the name of the FHIR resource validator used to validate
    #   each focus Bundle against the PAS Response Bundle profile with PasBundleValidation, which the including
    #   class must also include. Use NO_CUSTOM_EXTENSIONS_VALIDATOR for notifications Inferno sends, which may
    #   be tester-provided. When nil, only the PAS-specific structure is checked.
    # @param echoed_from [FHIR::Bundle, String, nil] the request Bundle that the focus Bundle answers - see
    #   PasBundleValidation#perform_bundle_validation.
    def verify_pas_notification(notification_json_str, focus_validator: nil, echoed_from: nil)
      check_pas_notification(notification_json_str, focus_validator:, echoed_from:)

      assert messages.none? { |msg| msg[:type] == 'error' },
             'The notification does not conform to PAS requirements - see messages for details.'
    end

    # Like verify_pas_notification, but only records the problems found as messages, for checking several
    # notifications in one test. It still fails the test when the notification is too malformed to check.
    def check_pas_notification(notification_json_str, focus_validator: nil, echoed_from: nil)
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

        validate_focus_as_response_bundle(focus_resource)
        next unless focus_resource.resourceType == 'Bundle' && focus_validator.present?

        validate_focus_against_profiles(focus_resource, focus_ref, focus_validator, echoed_from)
      end
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

    # Validates the focus Bundle as a $submit response, since it carries the final decision on a pended
    # $submit request.
    def validate_focus_against_profiles(focus_bundle, focus_ref, validator, echoed_from)
      focus_messages = perform_bundle_validation(focus_bundle, 'submit', 'response', PAS_NOTIFICATION_IG_VERSION,
                                                 validator:, echoed_from:)
      focus_messages.each do |message|
        add_message(message[:type], "Focus Bundle `#{focus_ref}`: #{message[:message]}")
      end
    rescue NoMethodError, TypeError, ArgumentError => e
      # a malformed Bundle (e.g., an entry with no resource) is reported rather than stopping the test
      add_message('error', "Focus Bundle `#{focus_ref}` could not be validated: #{e.message}")
    end
  end
end
