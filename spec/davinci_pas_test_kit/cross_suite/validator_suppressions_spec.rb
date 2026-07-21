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

  let(:nubc_code_system_not_found) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].revenue.coding[0]: ' \
      "A definition for CodeSystem 'https://www.nubc.org/revenue-code' could not be found, " \
      'so the code cannot be validated'
  end

  let(:nubc_value_set_membership_failure) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].revenue: ' \
      "None of the codings provided are in the value set 'AHA NUBC Revenue Value Set' " \
      '(http://hl7.org/fhir/us/davinci-pas/ValueSet/AHANUBCRevenueCodes|2.2.1), and a coding from this value set ' \
      'is required) (codes = https://www.nubc.org/revenue-code#0105)'
  end

  let(:x12278_value_set_membership_failure) do
    'Claim/HomecareAuthorizationExample: Claim.item[0].productOrService: ' \
      "None of the codings provided are in the value set 'X12 278 Requested Service Type' " \
      '(http://hl7.org/fhir/us/davinci-pas/ValueSet/X12278RequestedServiceType|2.2.1), and a coding from this ' \
      'value set is required)'
  end

  let(:extension_context_error) do
    'Claim/ReferralAuthorizationExample: Claim.supportingInfo[2]: ' \
      'The extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged v2.2.1 ' \
      'is not allowed to be used at this point (this element is [Backbone Element: Claim.supportingInfo])'
  end

  let(:modifier_extension_context_error) do
    'Claim/ReferralAuthorizationExample: Claim.supportingInfo[2]: ' \
      'The modifier extension http://hl7.org/fhir/us/davinci-pas/StructureDefinition/' \
      'modifierextension-infoCancelled v2.2.1 is not allowed to be used at this point'
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

      it 'excludes unresolvable X12 code system messages' do
        expect(exclude_message.call(validator_message(x12_code_system_not_found, 'warning'))).to be true
      end

      it 'excludes unresolvable NUBC revenue code system messages' do
        expect(exclude_message.call(validator_message(nubc_code_system_not_found, 'warning'))).to be true
      end

      it 'excludes code membership failures against the unexpandable NUBC revenue value set' do
        expect(exclude_message.call(validator_message(nubc_value_set_membership_failure, 'error'))).to be true
      end

      it 'excludes code membership failures against the unexpandable X12278RequestedServiceType value set' do
        expect(exclude_message.call(validator_message(x12278_value_set_membership_failure, 'error'))).to be true
      end

      it 'excludes extension context errors caused by IG defects' do
        expect(exclude_message.call(validator_message(extension_context_error, 'error'))).to be true
        expect(exclude_message.call(validator_message(modifier_extension_context_error, 'error'))).to be true
      end

      it 'does not exclude resolution failures for non-X12 value sets' do
        expect(exclude_message.call(validator_message(non_x12_value_set_not_found, 'warning'))).to be false
      end

      it 'does not exclude code membership failures against X12 value sets' do
        expect(exclude_message.call(validator_message(x12_value_set_membership_failure, 'error'))).to be false
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
      end

      it 'still excludes legacy suppression patterns' do
        expect(exclude_message.call(validator_message(hcpcs_code_system_not_found, 'warning'))).to be true
        expect(exclude_message.call(validator_message(profile_match_error, 'error'))).to be true
        expect(exclude_message.call(validator_message(all_ok_message, 'info'))).to be true
      end

      it 'does not exclude resolution failures for non-X12 value sets' do
        expect(exclude_message.call(validator_message(non_x12_value_set_not_found, 'warning'))).to be false
      end
    end
  end
end
