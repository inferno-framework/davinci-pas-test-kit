module DaVinciPASTestKit
  module DaVinciPASV201
    class PasSubmissionErrorTest < Inferno::Test
      id :prior_auth_submission_error
      title %(
        Server returns OperationOutcome instance when invoking the $submit operation on the Claim endpoint
        (/Claim/$submit) with nonconformant PAS Request Bundle
      )
      description %{
        A server SHALL support PAS prior authorization requests (a POST interaction to the /Claim/$submit endpoint).
        This test submits a Prior Authorization (PA) request containing an empty Bundle
        to the server and verifies that an OperationOutcome instance is returned with request
        status 400 when a nonconformant PAS Request Bundle is submitted.

        It is possible that the incoming prior authorization Bundle can not be processed due to validation errors or
        other non-business-errors. In these instances, the receiving system SHALL return OperationOutcome instances
        that detail why the Bundle could not be processed and no ClaimResponse will be returned. These errors are NOT
        the errors that are detected by the system processing the request and that can be conveyed in a ClaimResponse
        via the error capability.

        The server SHOULD respond within 15 seconds.
      }
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@70'

      output :response_time
      makes_request :pa_invalid_request

      run do
        file_path = File.join(File.dirname(__FILE__), 'nonconformant_pas_bundle.json')

        begin
          invalid_bundle_json = JSON.parse(File.read(file_path))
          start_time = Time.now
          fhir_operation('/Claim/$submit', body: invalid_bundle_json, name: :pa_invalid_request)
          end_time = Time.now
          response_time = end_time - start_time

          if response_time > 15
            warning %(
              The server took more that 15 seconds to respond to the Prior Authorization
              request.

              Response Time: #{response_time}
            )
          end

          assert !(200..299).include?(response[:status]), 'HTTP status code should not be within the 2xx range'
          assert_resource_type(:operation_outcome)

          output response_time:
        rescue JSON::ParserError => e
          skip "Internal error parsing the invalid bundle JSON: #{e.message}"
        end
      end
    end
  end
end
