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

  let(:non_x12_value_set_not_found) do
    'Patient/SubscriberExample: Patient.communication[0].language: ' \
      "ValueSet 'http://hl7.org/fhir/us/core/ValueSet/simple-language' not found"
  end

  let(:x12_code_not_in_value_set) do
    'Claim/ReferralAuthorizationExample: Claim.item[0].category: ' \
      'None of the codings provided are in the value set ' \
      "'https://valueset.x12.org/x217/005010/request/2000F/UM/1/03/00/1365', " \
      'and a coding from this value set is required'
  end

  [
    DaVinciPASTestKit::DaVinciPASV201::ServerSuite,
    DaVinciPASTestKit::DaVinciPASV221::ServerSuite,
    DaVinciPASTestKit::DaVinciPASV201::ClientSuite,
    DaVinciPASTestKit::DaVinciPASV221::ClientSuite
  ].each do |suite|
    describe "#{suite.title} validator message exclusions" do
      let(:exclude_message) { suite.fhir_validators[:default].first.exclude_message }

      def validator_message(text, type)
        Inferno::Entities::Message.new(type:, message: text)
      end

      it 'excludes unresolvable X12 value set messages at every severity' do
        %w[error warning info].each do |type|
          expect(exclude_message.call(validator_message(x12_value_set_not_found, type))).to be true
        end
      end

      it 'excludes unresolvable X12 code system messages' do
        expect(exclude_message.call(validator_message(x12_code_system_not_found, 'warning'))).to be true
      end

      it 'does not exclude resolution failures for non-X12 value sets' do
        expect(exclude_message.call(validator_message(non_x12_value_set_not_found, 'warning'))).to be false
      end

      it 'does not exclude code membership failures against X12 value sets' do
        expect(exclude_message.call(validator_message(x12_code_not_in_value_set, 'error'))).to be false
      end
    end
  end
end
