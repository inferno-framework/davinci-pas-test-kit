require_relative '../../../../../lib/davinci_pas_test_kit/client/v2.2.1/pas_client_attestations_group'

RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASClientAttestationsGroup, :runnable do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:group) { described_class }

  # The following list of requirements is derived from the requirements verified by each test in the group.
  let(:expected_requirements) do
    [
      'hl7.fhir.us.davinci-pas_2.2.1@conf-14',
      'hl7.fhir.us.davinci-pas_2.2.1@conf-15',
      'hl7.fhir.us.davinci-pas_2.2.1@conf-16',
      'hl7.fhir.us.davinci-pas_2.2.1@priv-1',
      'hl7.fhir.us.davinci-pas_2.2.1@use-5'
    ]
  end

  def attestation_input(test)
    test.available_inputs.values.find { |input| input.type == 'radio' }
  end

  def note_input(test)
    test.available_inputs.values.find { |input| input.type == 'textarea' }
  end

  it 'has one test per unique attestation title' do
    expect(group.tests.length).to eq(2)
    expect(group.tests.map(&:title).uniq.length).to eq(2)
  end

  it 'covers each attestation requirement exactly once' do
    covered = group.tests.flat_map(&:verifies_requirements).map(&:to_s)

    expect(covered).to match_array(expected_requirements)
  end

  describe 'each attestation test' do
    it 'is marked as an attestation' do
      expect(group.tests.reject(&:attestation?)).to be_empty
    end

    it 'collects an optional note' do
      group.tests.each do |test|
        input = note_input(test)

        expect(input).to_not be_nil, "#{test.title} has no notes input"
        expect(input.optional).to be(true), "#{test.title} notes input is not optional"
      end
    end

    it 'points testers at the specification requirements rather than restating them' do
      group.tests.each do |test|
        description = test.description.strip
        input_description = attestation_input(test).description.strip

        expect(description).to start_with('During this test, the tester will confirm that'),
                               "#{test.title} description does not open with the standard prefix"
        expect(description).to include('View Specification Requirements'),
                               "#{test.title} description does not point at the requirements"
        expect(input_description).to start_with('I attest that'),
                                     "#{test.title} input description does not open with 'I attest that'"
        expect(input_description).to_not include('https://'),
                                         "#{test.title} input description should not contain links"
      end
    end

    it 'carries the shared input instructions' do
      group.tests.each do |test|
        expect(test.input_instructions).to eq(group.input_instructions),
                                           "#{test.title} does not use the shared attestation input instructions"
      end
    end
  end

  describe 'attestation results' do
    let(:test) { group.tests.first }
    let(:attestation_name) { attestation_input(test).name.to_sym }
    let(:note_name) { note_input(test).name.to_sym }

    it 'passes when the tester answers Yes' do
      result = run(test, attestation_name => 'true')

      expect(result.result).to eq('pass')
    end

    it 'passes when the tester answers Yes and provides a note' do
      result = run(test, attestation_name => 'true', note_name => 'Verified during on-site review.')

      expect(result.result).to eq('pass')
    end

    it 'fails when the tester answers No' do
      result = run(test, attestation_name => 'false')

      expect(result.result).to eq('fail')
    end
  end
end
