module DaVinciPASTestKit
  # Helper module for working with FHIR Parameters resources in v2.2.1
  # Provides utilities to extract Bundles from Parameters.parameter entries
  module ParametersHelper
    # Extracts the resources from a Parameters resource's entries matching a given parameter name.
    # @param parameters [FHIR::Parameters] The Parameters resource
    # @param parameter_name [String] The Parameters.parameter.name to match, e.g. 'return' or 'resource'
    # @return [Array] Resources (one per matching entry, in order; nil for an entry with no resource)
    def extract_resources_from_parameters(parameters, parameter_name)
      return [] unless parameters.is_a?(FHIR::Parameters)

      parameters.parameter
        .select { |param| param.name == parameter_name }
        .map(&:resource)
    end

    # Extracts Bundles from a PAS Inquiry Response Parameters resource
    # @param parameters [FHIR::Parameters] The Parameters resource
    # @return [Array<FHIR::Bundle>] Array of Bundles from return parameters
    def extract_bundles_from_pas_inquiry_response_parameters(parameters)
      extract_resources_from_parameters(parameters, 'return') # rubocop:disable Style/SelectByKind
        .compact
        .select { |resource| resource.is_a?(FHIR::Bundle) }
    end
  end
end
