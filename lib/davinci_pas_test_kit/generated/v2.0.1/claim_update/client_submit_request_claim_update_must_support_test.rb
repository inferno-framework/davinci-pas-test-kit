require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ClientSubmitRequestClaimUpdateMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Claim Update are observed across all instances submitted'
      description %(
        
        PAS client systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Claim Update Profile.
        This test checks all identified instances of the PAS Claim Update
        Profile on requests sent by the client to ensure that the following
        must support elements are observed: 

        * Claim.accident
        * Claim.accident.date
        * Claim.accident.type
        * Claim.careTeam
        * Claim.careTeam.extension:careTeamClaimScope
        * Claim.careTeam.provider
        * Claim.careTeam.qualification
        * Claim.careTeam.role
        * Claim.careTeam.sequence
        * Claim.careTeam:ItemClaimMember.extension:careTeamClaimScope
        * Claim.careTeam:OverallClaimMember.extension:careTeamClaimScope
        * Claim.diagnosis
        * Claim.diagnosis.diagnosis[x]
        * Claim.diagnosis.extension:recordedDate
        * Claim.diagnosis.sequence
        * Claim.diagnosis.type
        * Claim.extension:encounter
        * Claim.extension:levelOfServiceType
        * Claim.identifier
        * Claim.insurance
        * Claim.insurance.coverage
        * Claim.insurance.sequence
        * Claim.insurer
        * Claim.item
        * Claim.item.careTeamSequence
        * Claim.item.category
        * Claim.item.diagnosisSequence
        * Claim.item.extension:administrationReferenceNumber
        * Claim.item.extension:authorizationNumber
        * Claim.item.extension:certificationType
        * Claim.item.extension:epsdtIndicator
        * Claim.item.extension:itemTraceNumber
        * Claim.item.extension:nursingHomeLevelOfCare
        * Claim.item.extension:nursingHomeResidentialStatus
        * Claim.item.extension:requestType
        * Claim.item.extension:requestedService
        * Claim.item.extension:revenueUnitRateLimit
        * Claim.item.informationSequence
        * Claim.item.location[x]
        * Claim.item.modifier
        * Claim.item.productOrService
        * Claim.item.quantity
        * Claim.item.revenue
        * Claim.item.sequence
        * Claim.item.serviced[x]
        * Claim.item.unitPrice
        * Claim.provider
        * Claim.supportingInfo
        * Claim.supportingInfo.category
        * Claim.supportingInfo.sequence
        * Claim.supportingInfo:AdditionalInformation
        * Claim.supportingInfo:AdditionalInformation.category
        * Claim.supportingInfo:AdditionalInformation.sequence
        * Claim.supportingInfo:AdditionalInformation.value[x]
        * Claim.supportingInfo:AdmissionDates.timing[x]
        * Claim.supportingInfo:DischargeDates.timing[x]
        * Claim.supportingInfo:MessageText
        * Claim.supportingInfo:MessageText.category
        * Claim.supportingInfo:MessageText.sequence
        * Claim.supportingInfo:MessageText.value[x]
        * Claim.supportingInfo:PatientEvent.timing[x]
      )

      id :pas_client_submit_request_v201_claim_update_must_support_test

      def resource_type
        'Claim'
      end

      def user_input_validation
        false
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        # The scratch key in MS test should be the same as the scratch key in the validation test for a given profile.
        scratch[:submit_request_resources] ||= {}
      end

      def resources_of_interest
        collection = tagged_resources(SUBMIT_TAG).presence || all_scratch_resources
        collection.select { |res| res.resourceType == resource_type }
      end

      run do
        perform_must_support_test(resources_of_interest)
        validate_must_support(user_input_validation)
      end
    end
  end
end
