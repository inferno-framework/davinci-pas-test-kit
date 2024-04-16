module DaVinciPASTestKit
  class Generator
    module MustSupportCheckProfiles
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

      OPTIONAL_PROFILES = [
        'PAS Medication Request',
        'PAS Service Request',
        'PAS Device Request',
        'PAS Nutrition Order'
      ].freeze

      class << self
        def submit_request_group?(group)
          SUBMIT_REQUEST_REQUIRED_PROFILES.include?(group.profile_name)
        end

        def submit_response_group?(group)
          SUBMIT_RESPONSE_REQUIRED_PROFILES.include?(group.profile_name)
        end

        def inquiry_request_group?(group)
          INQUIRY_REQUEST_REQUIRED_PROFILES.include?(group.profile_name)
        end

        def inquiry_response_group?(group)
          INQUIRY_RESPONSE_REQUIRED_PROFILES.include?(group.profile_name)
        end

        def optional_group?(group)
          OPTIONAL_PROFILES.include?(group.profile_name)
        end
      end
    end
  end
end
