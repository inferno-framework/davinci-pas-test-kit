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

    def fetch_tagged_resources
      resources = []
      load_tagged_requests(tag)
      return resources if requests.empty?

      requests.each do |req|
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
