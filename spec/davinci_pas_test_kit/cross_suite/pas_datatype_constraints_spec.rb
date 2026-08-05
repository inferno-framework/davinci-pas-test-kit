RSpec.describe DaVinciPASTestKit::PasDatatypeConstraints do
  let(:test_instance) do
    Class.new { include DaVinciPASTestKit::PasDatatypeConstraints }.new
  end

  let(:pas_profile_base) { described_class::PAS_STRUCTURE_DEFINITION_BASE }
  let(:device_request_profile) { "#{pas_profile_base}/profile-devicerequest" }
  let(:medication_request_profile) { "#{pas_profile_base}/profile-medicationrequest" }
  let(:service_request_profile) { "#{pas_profile_base}/profile-servicerequest" }
  let(:claim_profile) { "#{pas_profile_base}/profile-claim" }
  let(:claim_update_profile) { "#{pas_profile_base}/profile-claim-update" }
  let(:claim_response_profile) { "#{pas_profile_base}/profile-claimresponse" }

  def constraint_messages(resource, profile_url, version: '2.2.1')
    test_instance.datatype_constraint_messages(resource, profile_url, version)
  end

  def device_request_with(timing)
    FHIR::DeviceRequest.new(id: 'dr-1', occurrenceTiming: timing)
  end

  describe 'prof-1 (Timing)' do
    it 'passes when repeat.count is present' do
      timing = FHIR::Timing.new(repeat: FHIR::Timing::Repeat.new(count: 2))
      expect(constraint_messages(device_request_with(timing), device_request_profile)).to be_empty
    end

    it 'passes when frequency, period, and periodUnit are all present' do
      timing = FHIR::Timing.new(repeat: FHIR::Timing::Repeat.new(frequency: 3, period: 1, periodUnit: 'd'))
      expect(constraint_messages(device_request_with(timing), device_request_profile)).to be_empty
    end

    it 'passes when a calendarPattern extension is present' do
      timing = FHIR::Timing.new(
        extension: [FHIR::Extension.new(url: described_class::TIMING_CALENDAR_PATTERN_EXTENSION_URL)]
      )
      expect(constraint_messages(device_request_with(timing), device_request_profile)).to be_empty
    end

    it 'passes when a deliveryPattern extension is present' do
      timing = FHIR::Timing.new(
        extension: [FHIR::Extension.new(url: described_class::TIMING_DELIVERY_PATTERN_EXTENSION_URL)]
      )
      expect(constraint_messages(device_request_with(timing), device_request_profile)).to be_empty
    end

    it 'fails when frequency and period are present without periodUnit' do
      timing = FHIR::Timing.new(repeat: FHIR::Timing::Repeat.new(frequency: 3, period: 1))
      messages = constraint_messages(device_request_with(timing), device_request_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('prof-1').and(include('DeviceRequest/dr-1: DeviceRequest.occurrenceTiming')) }
      )
    end

    it 'fails when the Timing has no repeat and no pattern extensions' do
      messages = constraint_messages(device_request_with(FHIR::Timing.new), device_request_profile)
      expect(messages.first[:message]).to include('prof-1')
    end

    it 'checks each MedicationRequest dosageInstruction timing with an indexed location' do
      medication_request = FHIR::MedicationRequest.new(
        id: 'mr-1',
        dosageInstruction: [
          FHIR::Dosage.new(timing: FHIR::Timing.new(repeat: FHIR::Timing::Repeat.new(count: 1))),
          FHIR::Dosage.new(timing: FHIR::Timing.new)
        ]
      )
      messages = constraint_messages(medication_request, medication_request_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('MedicationRequest.dosageInstruction[1].timing') }
      )
    end

    it 'checks ServiceRequest.occurrenceTiming' do
      service_request = FHIR::ServiceRequest.new(id: 'sr-1', occurrenceTiming: FHIR::Timing.new)
      messages = constraint_messages(service_request, service_request_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('ServiceRequest.occurrenceTiming').and(include('prof-1')) }
      )
    end

    it 'passes when the resource has no Timing element' do
      expect(constraint_messages(FHIR::DeviceRequest.new(id: 'dr-1'), device_request_profile)).to be_empty
    end
  end

  describe 'prof-2 (Quantity value and unit or code)' do
    def claim_with_quantity(quantity)
      FHIR::Claim.new(id: 'claim-1', item: [FHIR::Claim::Item.new(sequence: 1, quantity:)])
    end

    it 'passes when value and unit are present' do
      quantity = FHIR::Quantity.new(value: 3, unit: 'days')
      expect(constraint_messages(claim_with_quantity(quantity), claim_profile)).to be_empty
    end

    it 'passes when value and a code with the X12 system are present' do
      quantity = FHIR::Quantity.new(value: 3, code: 'DA', system: described_class::X12_QUANTITY_UNITS_SYSTEM)
      expect(constraint_messages(claim_with_quantity(quantity), claim_profile)).to be_empty
    end

    it 'fails when the unit and code are both missing' do
      messages = constraint_messages(claim_with_quantity(FHIR::Quantity.new(value: 3)), claim_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('prof-2').and(include('Claim/claim-1: Claim.item[0].quantity')) }
      )
    end

    it 'fails when the value is missing' do
      messages = constraint_messages(claim_with_quantity(FHIR::Quantity.new(unit: 'days')), claim_profile)
      expect(messages.first[:message]).to include('prof-2')
    end

    it 'applies to profile-claim-update via profile-claim-base inheritance' do
      messages = constraint_messages(claim_with_quantity(FHIR::Quantity.new(value: 3)), claim_update_profile)
      expect(messages.first[:message]).to include('prof-2')
    end
  end

  describe 'prof-3 (X12 quantity units)' do
    it 'fails when a code uses a non-X12 system' do
      quantity = FHIR::Quantity.new(value: 3, code: 'd', system: 'http://unitsofmeasure.org')
      claim = FHIR::Claim.new(id: 'claim-1', item: [FHIR::Claim::Item.new(sequence: 1, quantity:)])
      messages = constraint_messages(claim, claim_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('prof-3').and(include(described_class::X12_QUANTITY_UNITS_SYSTEM)) }
      )
    end

    it 'passes when no code is present' do
      quantity = FHIR::Quantity.new(value: 3, unit: 'days')
      claim = FHIR::Claim.new(id: 'claim-1', item: [FHIR::Claim::Item.new(sequence: 1, quantity:)])
      expect(constraint_messages(claim, claim_profile)).to be_empty
    end
  end

  describe 'Quantity element locations' do
    let(:failing_quantity) { FHIR::Quantity.new(value: 3) }

    it 'checks ClaimResponse.addItem.quantity' do
      claim_response = FHIR::ClaimResponse.new(
        id: 'cr-1',
        addItem: [FHIR::ClaimResponse::AddItem.new(quantity: failing_quantity)]
      )
      messages = constraint_messages(claim_response, claim_response_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('ClaimResponse.addItem[0].quantity') }
      )
    end

    it 'checks the quantity inside the itemAuthorizedDetail extension' do
      claim_response = FHIR::ClaimResponse.new(
        id: 'cr-1',
        item: [
          FHIR::ClaimResponse::Item.new(
            itemSequence: 1,
            extension: [
              FHIR::Extension.new(
                url: described_class::ITEM_AUTHORIZED_DETAIL_EXTENSION_URL,
                extension: [FHIR::Extension.new(url: 'quantity', valueQuantity: failing_quantity)]
              )
            ]
          )
        ]
      )
      messages = constraint_messages(claim_response, claim_response_profile)

      expect(messages).to contain_exactly(
        { type: 'error',
          message: include('ClaimResponse.item[0].extension:authorizedItemDetail.extension:quantity.value') }
      )
    end

    it 'checks ServiceRequest.quantityQuantity' do
      service_request = FHIR::ServiceRequest.new(id: 'sr-1', quantityQuantity: failing_quantity)
      messages = constraint_messages(service_request, service_request_profile)

      expect(messages).to contain_exactly(
        { type: 'error', message: include('ServiceRequest.quantityQuantity') }
      )
    end
  end

  describe 'constraint applicability' do
    let(:nonconformant_device_request) { device_request_with(FHIR::Timing.new) }

    it 'does not apply for PAS v2.0.1' do
      expect(constraint_messages(nonconformant_device_request, device_request_profile, version: '2.0.1'))
        .to be_empty
    end

    it 'applies for v-prefixed 2.2.x version strings' do
      expect(constraint_messages(nonconformant_device_request, device_request_profile, version: 'v2.2.1'))
        .to_not be_empty
    end

    it 'does not apply when validating against a non-PAS profile' do
      us_core_profile = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'
      medication_request = FHIR::MedicationRequest.new(
        id: 'mr-1',
        dosageInstruction: [FHIR::Dosage.new(timing: FHIR::Timing.new)]
      )

      expect(constraint_messages(medication_request, us_core_profile)).to be_empty
    end

    it 'does not apply Quantity checks to profiles that only constrain Timing' do
      # DeviceRequest has no profiled Quantity element, so a DeviceRequest with only a
      # conformant Timing yields no messages even though the profile list overlaps
      timing = FHIR::Timing.new(repeat: FHIR::Timing::Repeat.new(count: 2))
      expect(constraint_messages(device_request_with(timing), device_request_profile)).to be_empty
    end
  end
end
