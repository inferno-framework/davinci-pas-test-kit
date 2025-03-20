module DaVinciPASTestKit
  module DaVinciPASV201
    class PasInquiryErrorTest < Inferno::Test
      id :prior_auth_inquiry_error
      title %(
        Server returns OperationOutcome instance when invoking the $inquire operation on the Claim endpoint
        (/Claim/$inquire) with nonconformant PAS Request Bundle
      )
      description %(
        A server SHALL support PAS Inquiry requests (a POST interaction to the /Claim/$inquire endpoint).
        This test submits a Prior Authorization Inquiry request containing an empty Bundle
        to the server and verifies that an OperationOutcome instance is returned with request
        status 400 when a nonconformant PAS Inquiry Bundle is submitted.

        It is possible that the incoming prior authorization Bundle can not be processed due to validation errors or
        other non-business-errors. In these instances, the receiving system SHALL return OperationOutcome instances
        that detail why the Bundle could not be processed and no ClaimResponse will be returned. These errors are NOT
        the errors that are detected by the system processing the request and that can be conveyed in a ClaimResponse
        via the error capability.
      )
      makes_request :pa_invalid_inquiry
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@112', 'hl7.fhir.us.davinci-pas_2.0.1@113'

      run do
        file_path = File.join(File.dirname(__FILE__), 'nonconformant_pas_bundle.json')

        begin
          invalid_bundle_json = JSON.parse(File.read(file_path))
          fhir_operation('/Claim/$inquire', body: invalid_bundle_json, name: :pa_invalid_inquiry)

          assert !(200..299).include?(response[:status]), 'HTTP status code should not be within the 2xx range'
          assert_resource_type(:operation_outcome)
        rescue JSON::ParserError => e
          skip "Internal error parsing the invalid bundle JSON: #{e.message}"
        end
      end
    end
  end
end
