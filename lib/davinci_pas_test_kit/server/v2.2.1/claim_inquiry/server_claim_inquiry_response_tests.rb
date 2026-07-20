require_relative '../../../parameters_helper'
require_relative '../../../cross_suite/pas_constants'
require_relative '../../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    module ServerClaimInquiryResponseValidation
      include ParametersHelper

      def inquiry_response_requests
        load_tagged_requests(INQUIRE_TAG)
      end

      def response_bundles
        inquiry_response_requests.flat_map do |request|
          parsed_resource = parsed_response_resource(request)
          next [] unless parsed_resource.is_a?(FHIR::Parameters)

          extract_bundles_from_pas_inquiry_response_parameters(parsed_resource)
        end
      end

      def parsed_response_resource(request)
        return if request&.response_body.blank?

        FHIR.from_contents(request.response_body)
      rescue StandardError
        nil
      end

      def claim_inquiry_responses
        response_bundles.flat_map { |bundle| Array(bundle.entry).filter_map { |entry| entry&.resource } }
          .grep(FHIR::ClaimResponse)
      end

      def claim_reference?(claim_response)
        claim_response.request&.reference.present?
      end

      def data_absent_reason?(claim_response)
        Array(claim_response.request&.extension).any? do |extension|
          extension.url == PASConstants::DATA_ABSENT_REASON_EXTENSION_URL && extension.valueCode.present?
        end
      end

      def claim_reference_or_data_absent_reason?(claim_response)
        claim_reference?(claim_response) || data_absent_reason?(claim_response)
      end

      def claim_response_label(claim_response, index)
        claim_response.id.present? ? "ClaimResponse/#{claim_response.id}" : "ClaimResponse at index #{index + 1}"
      end
    end

    class PASServerClaimInquiryResponseClaimReferenceTest < Inferno::Test
      include ServerClaimInquiryResponseValidation

      id :pas_server_v221_claim_inquiry_response_claim_reference_test
      title 'Server returns Claim Inquiry Responses with a Claim reference or Data Absent Reason'
      description %(
        The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/conformancedetails.html#ci-c-spec-44)
        each Claim Inquiry Response to either reference the Claim that triggered adjudication or carry
        a Data Absent Reason extension explaining why the Claim cannot be referenced.

        This test examines ClaimResponse resources returned by prior `$inquire` requests and verifies that
        each one includes either `ClaimResponse.request.reference` or the
        `data-absent-reason` extension on `ClaimResponse.request`.
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-44'

      run do
        claim_responses = claim_inquiry_responses
        skip_if claim_responses.empty?,
                'No Claim Inquiry Response ClaimResponse resources were returned by prior $inquire requests.'

        nonconformant = claim_responses.each_with_index.filter_map do |claim_response, index|
          next if claim_reference_or_data_absent_reason?(claim_response)

          claim_response_label(claim_response, index)
        end

        assert nonconformant.empty?,
               'The following Claim Inquiry Response resources did not include either ' \
               '`ClaimResponse.request.reference` or a Data Absent Reason extension on ' \
               "`ClaimResponse.request`: #{nonconformant.join(', ')}."
      end
    end
  end
end
