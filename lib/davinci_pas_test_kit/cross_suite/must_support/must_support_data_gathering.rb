require_relative '../../parameters_helper'
require_relative '../../generator/profile_metadata'

module DaVinciPASTestKit
  module MustSupportDataGathering
    include ParametersHelper

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

        # Handle Parameters resource (v2.2.0 inquire responses)
        if response_resource.resourceType == 'Parameters'
          bundles = extract_bundles_from_pas_inquiry_response_parameters(response_resource)
          bundles.each do |bundle|
            next unless bundle.is_a?(FHIR::Bundle)

            resources << bundle
            entry_resources = bundle.entry.map(&:resource)
            resources.concat(entry_resources)
          end
        elsif response_resource.is_a?(FHIR::Bundle)
          # Handle Bundle resource (v2.0.1 or v2.2.0 non-inquire)
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
