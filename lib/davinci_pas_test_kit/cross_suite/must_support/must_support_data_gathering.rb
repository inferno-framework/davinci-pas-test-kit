require_relative '../../parameters_helper'
require_relative '../../generator/profile_metadata'
require_relative '../tags'

module DaVinciPASTestKit
  module MustSupportDataGathering
    include ParametersHelper

    X12_SYSTEM_FRAGMENT = 'x12.org'.freeze
    X12_SLICE = 'Coverage.relationship.coding:X12Code'.freeze
    X12_CHILD = 'relationship.coding:X12Code.code'.freeze
    DATA_ABSENT_REASON_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'.freeze
    # Notifications Inferno sends to the PAS client
    NOTIFICATION_TAGS = [REST_HOOK_EVENT_NOTIFICATION_TAG, MUST_SUPPORT_NOTIFICATION_TAG].freeze

    # - Coverage.relationship.coding:X12Code has an empty required binding discriminator values
    #   list, so Inferno cannot reliably detect it automatically. Approximate by checking for an
    #   x12.org system on Coverage.relationship.coding.
    # - ClaimResponse.request may use DataAbsentReason; Inferno's generic navigation excludes
    #   DAR-bearing elements when checking the parent path, so treat an explicit DAR as satisfying
    #   the element.
    def remove_must_support_false_positives(missing_elements, resources, resource_type)
      return missing_elements if missing_elements.blank?

      if resource_type == 'Coverage' && missing_elements.include?(X12_SLICE)
        has_x12_coding = resources.any? do |resource|
          resource.relationship&.coding&.any? { |coding| coding.system&.include?(X12_SYSTEM_FRAGMENT) }
        end
        missing_elements -= [X12_SLICE, X12_CHILD] if has_x12_coding
      end

      if resource_type == 'ClaimResponse' && missing_elements.include?('request')
        has_request_data_absent_reason = resources.any? do |resource|
          resource.request&.extension&.any? { |extension| extension.url == DATA_ABSENT_REASON_URL }
        end
        missing_elements -= ['request'] if has_request_data_absent_reason
      end

      missing_elements
    end

    def load_metadata_for_profile_version(profile_key, version)
      Generator::ProfileMetadata.new(
        YAML.load_file(File.join(__dir__, '..', 'generated', version, profile_key, 'metadata.yml'), aliases: true)
      )
    end

    def tag
      case operation
      when 'submit'
        SUBMIT_TAG
      when 'inquire'
        INQUIRE_TAG
      end
    end

    # v2.2.1 $submit responses also include the notifications Inferno sends after pended responses
    def tags
      return [tag] unless type == 'response' && operation == 'submit' && ig_version == 'v2.2.1'

      [tag, *NOTIFICATION_TAGS]
    end

    def tagged_resources
      @tagged_resources ||= fetch_tagged_resources
    end

    # The tagged requests whose bodies are assessed for must support. By default this uses
    # load_tagged_requests, which also associates the requests with this test's result. Tests that
    # should not own (and thereby duplicate) that association can override must_support_requests to
    # read the requests without associating them.
    def must_support_requests
      tags.each { |request_tag| load_tagged_requests(request_tag) }
      requests
    end

    def fetch_tagged_resources
      # Each tag is loaded separately, so a request with more than one would repeat
      Array(must_support_requests).uniq(&:id).flat_map { |req| resources_from_request(req) }
    end

    def resources_from_request(req)
      notification = notification_request?(req)
      body = notification || type == 'request' ? req.request_body : req.response_body
      begin
        resource = FHIR.from_contents(body)
      rescue StandardError
        return []
      end

      if notification
        notification_resources(resource)
      elsif resource.is_a?(FHIR::Parameters) # v2.2.1 inquire responses
        extract_bundles_from_pas_inquiry_response_parameters(resource)
          .grep(FHIR::Bundle)
          .flat_map { |bundle| bundle_and_entry_resources(bundle) }
      elsif resource.is_a?(FHIR::Bundle) # v2.0.1 or v2.2.1 non-inquire
        bundle_and_entry_resources(resource)
      else
        []
      end
    end

    # Inferno sends notifications, so their content is in the request body
    def notification_request?(req)
      Array(req.tags).intersect?(NOTIFICATION_TAGS)
    end

    # Leaves out the notification Bundle itself and its SubscriptionStatus
    def notification_resources(notification)
      return [] unless notification.is_a?(FHIR::Bundle)

      Array(notification.entry).map(&:resource).flat_map do |resource|
        next [] if resource.nil? || resource.is_a?(FHIR::Parameters)

        resource.is_a?(FHIR::Bundle) ? bundle_and_entry_resources(resource) : [resource]
      end
    end

    def bundle_and_entry_resources(bundle)
      [bundle, *Array(bundle.entry).map(&:resource).compact]
    end

    def resources_of_interest
      @resources_of_interest ||=
        tagged_resources.presence&.select { |res| type_of_interest?(res.resourceType) }
    end

    def error_message(missing, resources, resource_type)
      "Could not find #{missing.join(', ')} in the #{resources.length} provided #{resource_type} resource(s)."
    end
  end
end
