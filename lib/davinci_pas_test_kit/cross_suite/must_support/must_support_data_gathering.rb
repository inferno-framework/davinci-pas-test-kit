require_relative '../../parameters_helper'
require_relative '../../generator/profile_metadata'

module DaVinciPASTestKit
  module MustSupportDataGathering
    include ParametersHelper

    X12_SYSTEM_FRAGMENT = 'x12.org'.freeze
    X12_SLICE = 'Coverage.relationship.coding:X12Code'.freeze
    X12_CHILD = 'relationship.coding:X12Code.code'.freeze
    DATA_ABSENT_REASON_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'.freeze

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

    def tagged_resources
      @tagged_resources ||= fetch_tagged_resources
    end

    # The tagged requests whose bodies are assessed for must support. By default this uses
    # load_tagged_requests, which also associates the requests with this test's result. Tests that
    # should not own (and thereby duplicate) that association can override must_support_requests to
    # read the requests without associating them.
    def must_support_requests
      load_tagged_requests(tag)
      requests
    end

    # $submit responses may also be delivered later via a Subscription notification (the pended
    # workflow's finalized decision), rather than directly in the $submit response - see
    # DaVinciPASTestKit::ResponseGenerator#mock_full_resource_notification_bundle. By default this
    # uses load_tagged_requests, associating the requests with this test's result; tests that should
    # not own that association can override notification_requests as must_support_requests does.
    def notification_requests
      load_tagged_requests(REST_HOOK_EVENT_NOTIFICATION_TAG)
    end

    # A full-resource notification's outer Bundle carries the $submit response Bundle nested in one
    # of its entries (alongside the SubscriptionStatus entry), rather than as the notification's own
    # resourceType, so it needs to be extracted before it can be assessed like any other $submit
    # response Bundle.
    def bundles_from_notification(notification_request)
      notification_bundle = FHIR.from_contents(notification_request.request_body)
      return [] unless notification_bundle.is_a?(FHIR::Bundle)

      notification_bundle.entry.to_a.filter_map { |entry| entry.resource if entry.resource.is_a?(FHIR::Bundle) }
    rescue StandardError
      []
    end

    # A notification Inferno failed to deliver (a non-2xx response, or none at all - see
    # DaVinciPASTestKit::Jobs::SendPASSubscriptionNotification#send_notification) never reached the
    # client, so its contents cannot count as something the client demonstrated must support for.
    def successful_notification?(notification_request)
      (200..299).cover?(notification_request.status.to_i)
    end

    def fetch_tagged_resources
      resources = []
      tagged = must_support_requests
      return resources if tagged.blank?

      tagged.each do |req|
        begin
          response_resource = FHIR.from_contents(type == 'request' ? req.request_body : req.response_body)
        rescue StandardError
          next
        end

        next unless response_resource.present?

        # Handle Parameters resource (v2.2.1 inquire responses)
        if response_resource.resourceType == 'Parameters'
          bundles = extract_bundles_from_pas_inquiry_response_parameters(response_resource)
          bundles.each do |bundle|
            next unless bundle.is_a?(FHIR::Bundle)

            resources << bundle
            entry_resources = bundle.entry.map(&:resource)
            resources.concat(entry_resources)
          end
        elsif response_resource.is_a?(FHIR::Bundle)
          # Handle Bundle resource (v2.0.1 or v2.2.1 non-inquire)
          resources << response_resource
          entry_resources = response_resource.entry.map(&:resource)
          resources.concat(entry_resources)
        end
      end

      if operation == 'submit' && type == 'response'
        notification_requests.each_with_index do |req, index|
          unless successful_notification?(req)
            add_message('info',
                        "Subscription notification #{index + 1} was not successfully delivered (delivery " \
                        "status #{req.status.inspect}), so its contents were not included in the must " \
                        'support analysis.')
            next
          end

          bundles_from_notification(req).each do |bundle|
            resources << bundle
            resources.concat(bundle.entry.to_a.map(&:resource))
          end
        end
      end

      resources
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
