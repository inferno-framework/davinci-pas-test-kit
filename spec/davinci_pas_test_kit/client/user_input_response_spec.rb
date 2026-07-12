require_relative '../../../lib/davinci_pas_test_kit/client/user_input_response'

RSpec.describe DaVinciPASTestKit::UserInputResponse do
  describe '.response_candidates' do
    let(:bundle_a) { { 'resourceType' => 'Bundle', 'id' => 'bundle-a' } }
    let(:bundle_b) { { 'resourceType' => 'Bundle', 'id' => 'bundle-b' } }
    let(:wrapped_bundle) { { 'criteria' => { 'requestRange' => '1' }, 'bundle' => bundle_b } }

    def result_with_input(name, value)
      instance_double(Inferno::Entities::Result, input_json: [{ 'name' => name, 'value' => value }].to_json)
    end

    it 'returns a one-element list for a single bare bundle' do
      result = result_with_input('ms_submit_responses', bundle_a.to_json)

      expect(described_class.response_candidates(result, 'submit')).to eq([bundle_a])
    end

    it 'returns a one-element list for a single wrapper object' do
      result = result_with_input('ms_submit_responses', wrapped_bundle.to_json)

      expect(described_class.response_candidates(result, 'submit')).to eq([wrapped_bundle])
    end

    it 'returns all entries for a list mixing bare bundles and wrapper objects' do
      result = result_with_input('ms_submit_responses', [wrapped_bundle, bundle_a].to_json)

      expect(described_class.response_candidates(result, 'submit')).to eq([wrapped_bundle, bundle_a])
    end

    it 'reads the ms_inquire_responses input for the inquire operation' do
      result = result_with_input('ms_inquire_responses', [bundle_b].to_json)

      expect(described_class.response_candidates(result, 'inquire')).to eq([bundle_b])
    end

    it 'returns nil when the input has no value' do
      result = result_with_input('ms_submit_responses', nil)

      expect(described_class.response_candidates(result, 'submit')).to be_nil
    end

    it 'returns nil when the input is not valid JSON' do
      result = result_with_input('ms_submit_responses', 'not json')

      expect(described_class.response_candidates(result, 'submit')).to be_nil
    end

    it 'returns nil when the input contains entries that are not objects' do
      result = result_with_input('ms_submit_responses', [bundle_a, 'not a bundle'].to_json)

      expect(described_class.response_candidates(result, 'submit')).to be_nil
    end

    it 'returns nil when a wrapper is missing its bundle' do
      result = result_with_input('ms_submit_responses', [{ 'criteria' => { 'requestRange' => '1' } }].to_json)

      expect(described_class.response_candidates(result, 'submit')).to be_nil
    end
  end
end
