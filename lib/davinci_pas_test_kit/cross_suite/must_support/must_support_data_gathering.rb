require_relative '../../generator/group_metadata'

module DaVinciPASTestKit
  module MustSupportDataGathering
    def load_metadata_for_profile_version(profile_key, version)
      Generator::GroupMetadata.new(
        YAML.load_file(File.join(__dir__, '..', 'generated', version, profile_key, 'metadata.yml'), aliases: true)
      )
    end

    def all_scratch_resources
      scratch_resources[:all] ||= []
    end

    def scratch_resources
      scratch[scratch_key] ||= {}
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
          bundle = FHIR.from_contents(req.request_body)
        rescue StandardError
          next
        end

        next unless bundle.is_a?(FHIR::Bundle)

        resources << bundle
        entry_resources = bundle.entry.map(&:resource)
        resources.concat(entry_resources)
      end

      resources
    end

    def resources_of_interest
      @resources_of_interest ||=
        (tagged_resources.presence || all_scratch_resources)
          .select { |res| type_of_interest?(res.resourceType) }
    end

    def error_message(missing, resources, resource_type)
      "Could not find #{missing.join(', ')} in the #{resources.length} provided #{resource_type} resource(s)."
    end
  end
end
