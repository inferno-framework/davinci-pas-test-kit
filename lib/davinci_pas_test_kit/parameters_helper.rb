module DaVinciPASTestKit
  # Helper module for working with FHIR Parameters resources in v2.2.0
  # Provides utilities to extract Bundles from Parameters.parameter entries
  module ParametersHelper
    # Extracts Bundles from a PAS Inquiry Response Parameters resource
    # @param parameters [FHIR::Parameters] The Parameters resource
    # @return [Array<FHIR::Bundle>] Array of Bundles from return parameters
    def extract_bundles_from_pas_inquiry_response_parameters(parameters)
      return [] unless parameters.is_a?(FHIR::Parameters)

      parameters.parameter
        .select { |param| param.name == 'return' }
        .map(&:resource)
        .compact
        .select { |resource| resource.is_a?(FHIR::Bundle) }
    end
  end
end
