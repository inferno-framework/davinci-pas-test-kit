module DaVinciPASTestKit
  class Generator
    module MustSupportTargetProfiles
      SUBMIT_REQUEST_REQUIRED_PROFILES = [
        'PAS Request Bundle',
        'PAS Beneficiary Patient',
        'PAS Claim Update',
        'PAS Coverage',
        'PAS Device Request',
        'PAS Encounter',
        'PAS Insurer Organization',
        'PAS Medication Request',
        'PAS Nutrition Order',
        'PAS Practitioner',
        'PAS PractitionerRole',
        'PAS Requestor Organization',
        'PAS Service Request',
        'PAS Subscriber Patient'
      ].freeze

      SUBMIT_RESPONSE_REQUIRED_PROFILES = [
        'PAS Beneficiary Patient',
        'PAS Claim Response',
        'PAS CommunicationRequest',
        'PAS Insurer Organization',
        'PAS Practitioner',
        'PAS PractitionerRole',
        'PAS Requestor Organization',
        'PAS Response Bundle',
        'PAS Task'
      ].freeze

      INQUIRY_REQUEST_REQUIRED_PROFILES = [
        'PAS Beneficiary Patient',
        'PAS Claim Inquiry',
        'PAS Coverage',
        'PAS Inquiry Request Bundle',
        'PAS Insurer Organization',
        'PAS Practitioner',
        'PAS PractitionerRole',
        'PAS Requestor Organization',
        'PAS Subscriber Patient'
      ].freeze

      INQUIRY_RESPONSE_REQUIRED_PROFILES = [
        'PAS Beneficiary Patient',
        'PAS Claim Inquiry Response',
        'PAS Inquiry Response Bundle',
        'PAS Insurer Organization',
        'PAS Practitioner',
        'PAS PractitionerRole',
        'PAS Requestor Organization',
        'PAS Task'
      ].freeze

      REQUEST_PROFILES = [
        'PAS Medication Request',
        'PAS Service Request',
        'PAS Device Request',
        'PAS Nutrition Order'
      ].freeze

      class << self
        def submit_request_profile?(profile_metadata)
          SUBMIT_REQUEST_REQUIRED_PROFILES.include?(profile_metadata.profile_name)
        end

        def submit_response_profile?(profile_metadata)
          SUBMIT_RESPONSE_REQUIRED_PROFILES.include?(profile_metadata.profile_name)
        end

        def inquire_request_profile?(profile_metadata)
          INQUIRY_REQUEST_REQUIRED_PROFILES.include?(profile_metadata.profile_name)
        end

        def inquire_response_profile?(profile_metadata)
          INQUIRY_RESPONSE_REQUIRED_PROFILES.include?(profile_metadata.profile_name)
        end

        def request_profile?(profile_metadata)
          REQUEST_PROFILES.include?(profile_metadata.profile_name)
        end
      end
    end
  end
end
