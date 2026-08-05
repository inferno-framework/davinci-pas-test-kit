RSpec.describe DaVinciPASTestKit do
  let(:x12_value_set_not_found) do
    'Claim/ReferralAuthorizationExample: Claim.extension[0].value.ofType(CodeableConcept): ' \
      "ValueSet 'https://valueset.x12.org/x217/005010/request/2000E/UM/1/06/00/1338' not found " \
      '(validating against http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim|2.2.1 [PASClaim])'
  end

  let(:x12_code_system_not_found) do
    'Organization/UMOExample: Organization.type[0].coding[0]: ' \
      "A definition for CodeSystem 'https://codesystem.x12.org/005010/98' could not be found, " \
      'so the code cannot be validated ' \
      '(validating against http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-requestor|2.2.1 ' \
      '[PASRequestor])'
  end

  # Some X12 codes are referenced with a valueset.x12.org URL as their code system.
  let(:x12_code_system_not_found_valueset_url) do
    'ClaimResponse/ReferralAuthorizationResponseExample: ' \
      'ClaimResponse.addItem[0].extension[6].value.ofType(CodeableConcept).coding[0].system: ' \
      "A definition for CodeSystem 'https://valueset.x12.org/x217/005010/response/2000F/NX1/1/01/00/1345' " \
      'could not be found, so the code cannot be validated'
  end

  # NUBC revenue codes are proprietary; the example data references the code system under both URLs.
  let(:nubc_code_system_not_found) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].revenue.coding[0]: ' \
      "A definition for CodeSystem 'https://www.nubc.org/revenue-code' could not be found, " \
      'so the code cannot be validated'
  end

  let(:nubc_code_system_not_found_alt_url) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].revenue.coding[0]: ' \
      "A definition for CodeSystem 'https://www.nubc.org/CodeSystem/RevenueCodes' could not be found, " \
      'so the code cannot be validated'
  end

  # Extension-placement errors carry the element context in the message as "(this element is [...])".
  # Each fixture below uses the exact context the IG defect forces.
  let(:authorization_number_at_claim) do
    'Claim/ReferralAuthorizationExample: Claim.extension[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizationNumber v2.2.1 ' \
      'is not allowed to be used at this point (this element is [Claim]; ' \
      'allowed for this version = e:Claim.item, e:ClaimResponse.item)'
  end

  let(:info_changed_at_supporting_info) do
    'Claim/ReferralAuthorizationExample: Claim.supportingInfo[2]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged v2.2.1 ' \
      'is not allowed to be used at this point (this element is [BackboneElement, Claim.supportingInfo]; ' \
      'allowed for this version = e:Claim.item)'
  end

  let(:info_cancelled_at_supporting_info) do
    'Claim/ReferralAuthorizationExample: Claim.supportingInfo[2]: ' \
      'The modifier extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/' \
      'modifierextension-infoCancelled v2.2.1 is not allowed to be used at this point ' \
      '(this element is [BackboneElement, Claim.supportingInfo]; allowed = e:Claim.item)'
  end

  let(:certification_type_at_add_item) do
    'ClaimResponse/ReferralAuthorizationResponseExample: ClaimResponse.addItem[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-certificationType v2.2.1 ' \
      'is not allowed to be used at this point (this element is [BackboneElement, ClaimResponse.addItem]; ' \
      'allowed for this version = e:Claim, e:Claim.item)'
  end

  let(:product_or_service_code_end_at_service_request) do
    'ServiceRequest/ReferralRequestExample: ServiceRequest.extension[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-productOrServiceCodeEnd v2.2.1 ' \
      'is not allowed to be used at this point (this element is [ServiceRequest]; ' \
      'allowed for this version = e:Claim.item, e:ClaimResponse)'
  end

  let(:product_or_service_code_end_at_add_item) do
    'ClaimResponse/ReferralAuthorizationResponseExample: ClaimResponse.addItem[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-productOrServiceCodeEnd v2.2.1 ' \
      'is not allowed to be used at this point (this element is [BackboneElement, ClaimResponse.addItem]; ' \
      'allowed for this version = e:Claim.item, e:ClaimResponse)'
  end

  # Same extensions, but at a genuinely wrong location: these must NOT be suppressed.
  let(:authorization_number_at_wrong_location) do
    'Patient/SubscriberExample: Patient.extension[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizationNumber v2.2.1 ' \
      'is not allowed to be used at this point (this element is [Patient]; ' \
      'allowed for this version = e:Claim.item)'
  end

  let(:info_changed_at_wrong_location) do
    'Claim/ReferralAuthorizationExample: Claim.extension[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged v2.2.1 ' \
      'is not allowed to be used at this point (this element is [Claim]; allowed for this version = e:Claim.item)'
  end

  let(:certification_type_at_wrong_location) do
    'Claim/ReferralAuthorizationExample: Claim.item[0]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-certificationType v2.2.1 ' \
      'is not allowed to be used at this point (this element is [BackboneElement, Claim.item]; allowed = e:Claim)'
  end

  let(:non_x12_value_set_not_found) do
    'Patient/SubscriberExample: Patient.communication[0].language: ' \
      "ValueSet 'http://hl7.org/fhir/us/core/ValueSet/simple-language' not found"
  end

  let(:x12_value_set_membership_failure) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].category: ' \
      'None of the codings provided are in the value set ' \
      "'https://valueset.x12.org/x217/005010/request/2000F/UM/1/03/00/1365', " \
      'and a coding from this value set is required'
  end

  # NUBC revenue codes are must-support (not required), so the element is empty in the IG examples
  # but populated by the must support tests; the value set cannot be expanded, so the membership
  # check is unactionable and is suppressed.
  let(:nubc_value_set_membership_failure) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].revenue: ' \
      "None of the codings provided are in the value set 'AHA NUBC Revenue Value Set' " \
      '(http://hl7.org/fhir/us/davinci-pas/ValueSet/AHANUBCRevenueCodes|2.2.1), and a coding from this value set ' \
      'is required'
  end

  # Other PAS-defined value sets whose members are entirely X12 codes; membership is unactionable.
  let(:pwk01_value_set_membership_failure) do
    'DocumentReference/DocumentReferenceExample: DocumentReference.type: ' \
      "None of the codings provided are in the value set 'PAS PWK01 Attachment Report Type Code Value Set' " \
      '(http://hl7.org/fhir/us/davinci-pas/ValueSet/pas-pwk01-attachment-report-type-code|2.2.1), and a coding ' \
      'should come from this value set'
  end

  let(:communication_medium_value_set_membership_failure) do
    'CommunicationRequest/CommunicationRequestExample: CommunicationRequest.medium[0]: ' \
      "None of the codings provided are in the value set 'PAS Communication Medium Value Set' " \
      '(http://hl7.org/fhir/us/davinci-pas/ValueSet/PASCommunicationRequestMedium|2.2.1), and a coding from this ' \
      'value set is required'
  end

  let(:details_for_matching_profile) do
    'Bundle/ReferralAuthorizationBundleExample: Bundle.entry[0]: ' \
      'Details for Claim/ReferralAuthorizationExample matching against profile ' \
      'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim|2.2.1'
  end

  let(:hcpcs_code_system_not_found) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].productOrService.coding[0]: ' \
      "A definition for CodeSystem 'http://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets' " \
      'could not be found, so the code cannot be validated'
  end

  let(:profile_match_error) do
    'Bundle/ReferralAuthorizationBundleExample: Bundle.entry[3]: ' \
      'Unable to find a profile match for Coverage/InsuranceExample among choices: ' \
      'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-coverage|2.2.1'
  end

  let(:all_ok_message) do
    'Bundle.entry[0].resource.ofType(Claim): All OK'
  end

  def validator_message(text, type)
    Inferno::Entities::Message.new(type:, message: text)
  end

  [
    DaVinciPASTestKit::DaVinciPASV221::ServerSuite,
    DaVinciPASTestKit::DaVinciPASV221::ClientSuite
  ].each do |suite|
    describe "#{suite.title} validator message exclusions" do
      let(:exclude_message) { suite.fhir_validators[:default].first.exclude_message }

      it 'excludes unresolvable X12 value set messages at every severity' do
        %w[error warning info].each do |type|
          expect(exclude_message.call(validator_message(x12_value_set_not_found, type))).to be true
        end
      end

      it 'excludes unresolvable X12 code system messages under either x12.org subdomain' do
        expect(exclude_message.call(validator_message(x12_code_system_not_found, 'warning'))).to be true
        expect(exclude_message.call(validator_message(x12_code_system_not_found_valueset_url, 'warning'))).to be true
      end

      it 'excludes unresolvable NUBC revenue code system messages under either code system URL' do
        expect(exclude_message.call(validator_message(nubc_code_system_not_found, 'warning'))).to be true
        expect(exclude_message.call(validator_message(nubc_code_system_not_found_alt_url, 'warning'))).to be true
      end

      it 'excludes IG-defect extension placement errors at the specific forced location' do
        expect(exclude_message.call(validator_message(authorization_number_at_claim, 'error'))).to be true
        expect(exclude_message.call(validator_message(info_changed_at_supporting_info, 'error'))).to be true
        expect(exclude_message.call(validator_message(info_cancelled_at_supporting_info, 'error'))).to be true
        expect(exclude_message.call(validator_message(certification_type_at_add_item, 'error'))).to be true
      end

      it 'excludes productOrServiceCodeEnd at both forced locations (ServiceRequest and addItem)' do
        expect(exclude_message.call(validator_message(product_or_service_code_end_at_service_request, 'error')))
          .to be true
        expect(exclude_message.call(validator_message(product_or_service_code_end_at_add_item, 'error'))).to be true
      end

      it 'excludes code membership failures against the unexpandable NUBC revenue value set' do
        expect(exclude_message.call(validator_message(nubc_value_set_membership_failure, 'error'))).to be true
      end

      it 'excludes code membership failures against all-X12 PAS-defined value sets' do
        expect(exclude_message.call(validator_message(pwk01_value_set_membership_failure, 'warning'))).to be true
        expect(exclude_message.call(validator_message(communication_medium_value_set_membership_failure, 'error')))
          .to be true
      end

      it 'does not exclude the same extensions when used at a genuinely wrong location' do
        expect(exclude_message.call(validator_message(authorization_number_at_wrong_location, 'error'))).to be false
        expect(exclude_message.call(validator_message(info_changed_at_wrong_location, 'error'))).to be false
        expect(exclude_message.call(validator_message(certification_type_at_wrong_location, 'error'))).to be false
      end

      it 'does not exclude resolution failures for non-X12 value sets' do
        expect(exclude_message.call(validator_message(non_x12_value_set_not_found, 'warning'))).to be false
      end

      it 'does not exclude code membership failures against X12 value sets' do
        expect(exclude_message.call(validator_message(x12_value_set_membership_failure, 'error'))).to be false
      end

      it 'does not exclude informational profile-slice-matching messages' do
        expect(exclude_message.call(validator_message(details_for_matching_profile, 'info'))).to be false
      end

      it 'does not exclude legacy-only patterns dropped from the targeted list' do
        expect(exclude_message.call(validator_message(hcpcs_code_system_not_found, 'warning'))).to be false
        expect(exclude_message.call(validator_message(profile_match_error, 'error'))).to be false
        expect(exclude_message.call(validator_message(all_ok_message, 'info'))).to be false
      end
    end
  end

  [
    DaVinciPASTestKit::DaVinciPASV201::ServerSuite,
    DaVinciPASTestKit::DaVinciPASV201::ClientSuite
  ].each do |suite|
    describe "#{suite.title} validator message exclusions" do
      let(:exclude_message) { suite.fhir_validators[:default].first.exclude_message }

      it 'excludes the targeted X12 patterns at every severity' do
        %w[error warning info].each do |type|
          expect(exclude_message.call(validator_message(x12_value_set_not_found, type))).to be true
        end
        expect(exclude_message.call(validator_message(x12_code_system_not_found, 'warning'))).to be true
        expect(exclude_message.call(validator_message(x12_code_system_not_found_valueset_url, 'warning'))).to be true
      end

      it 'still excludes legacy suppression patterns' do
        expect(exclude_message.call(validator_message(hcpcs_code_system_not_found, 'warning'))).to be true
        expect(exclude_message.call(validator_message(profile_match_error, 'error'))).to be true
        expect(exclude_message.call(validator_message(all_ok_message, 'info'))).to be true
      end

      # The v2.0.1 list keeps the original location-blind extension suppressions, so it still
      # excludes these placement errors regardless of where the extension was seen. The location
      # anchoring only applies to the v2.2.1 list.
      it 'excludes extension placement errors regardless of location' do
        expect(exclude_message.call(validator_message(authorization_number_at_claim, 'error'))).to be true
        expect(exclude_message.call(validator_message(authorization_number_at_wrong_location, 'error'))).to be true
      end

      it 'does not exclude resolution failures for non-X12 value sets' do
        expect(exclude_message.call(validator_message(non_x12_value_set_not_found, 'warning'))).to be false
      end
    end
  end
end
