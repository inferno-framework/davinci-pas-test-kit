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

    # Wraps missing_must_support_elements to handle :optional_slices in the metadata.
    #
    # Some non-MS parent slices (e.g. Claim.supportingInfo:PatientEvent in v2.0.1) have MS
    # children (e.g. timing[x]). These slices are stored in :optional_slices rather than :slices
    # so they are not asserted as independently required. However, their discriminator info must
    # be visible to inferno_core's find_slice_via_discriminator so it can navigate into the slice
    # to check the MS children.
    #
    # This method merges :optional_slices into :slices on a patched copy of the metadata before
    # calling missing_must_support_elements. The result is returned unchanged: if the parent slice
    # is absent the child elements will still appear as missing (a failure), and if the parent is
    # present but a child is absent that child also appears as missing (a failure). The test
    # passes only when the parent slice is present and all its MS children are populated.
    def missing_must_support_elements_with_optional_slices(resources, metadata)
      optional_slices = metadata.must_supports[:optional_slices] || []
      return missing_must_support_elements(resources, nil, metadata:) if optional_slices.empty?

      patched_ms = metadata.must_supports.merge(
        slices: (metadata.must_supports[:slices] || []) + optional_slices
      )
      working_metadata = Struct.new(:must_supports).new(patched_ms)
      missing_must_support_elements(resources, nil, metadata: working_metadata)
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
