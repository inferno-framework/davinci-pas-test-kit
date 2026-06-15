# frozen_string_literal: true

module DaVinciPASTestKit
  # Serves the simulated PAS payer server's CapabilityStatement so that
  # clients under test can discover its capabilities, including subscription support, as
  # required by the PAS IG.
  module MockPASServer
    CAPABILITY_STATEMENT_PATH = File.join(__dir__, 'pas_server_capability_statement.json').freeze

    class << self
      # @return [String] the simulated server's CapabilityStatement as a JSON string
      def capability_statement_json
        @capability_statement_json ||= File.read(CAPABILITY_STATEMENT_PATH)
      end

      # Rack response for a FHIR `GET [base]/metadata` request
      def capability_statement_response(_env = nil)
        [
          200,
          { 'Content-Type' => 'application/fhir+json', 'Access-Control-Allow-Origin' => '*' },
          [capability_statement_json]
        ]
      end
    end
  end
end
