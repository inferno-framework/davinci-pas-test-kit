module DaVinciPASTestKit
  module PASConstants
    CLAIM_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim-update'.freeze
    CLAIM_RESPONSE_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claimresponse'.freeze
    CLAIM_INQUIRY_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim-inquiry'.freeze
    CLAIM_INQUIRY_RESPONSE_PROFILE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claiminquiryresponse'.freeze

    BUNDLE_PROFILES_FOR_OPERATION_TYPE = {
      submit_request: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
      submit_response: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle',
      inquire_request: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle',
      inquire_response: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-response-bundle'
    }.freeze

    def self.bundle_profile_url_for_operation_and_type(operation, type)
      BUNDLE_PROFILES_FOR_OPERATION_TYPE[:"#{operation}_#{type}"]
    end

    def self.bundle_profile_name_for_operation_and_type(operation, type)
      url = bundle_profile_url_for_operation_and_type(operation, type)
      url.split('/profile-').last.titleize.gsub('Pas', 'PAS')
    end

    X12_ADJUDICATION_CODES = {
      approval: 'A1',
      denial: 'A3',
      pended: 'A4'
    }.freeze
  end
end
