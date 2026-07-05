require_relative '../../../lib/davinci_pas_test_kit/client/user_input_response'

RSpec.describe DaVinciPASTestKit::UserInputResponse do
  describe '.response_bundles' do
    let(:bundle_a) { { 'resourceType' => 'Bundle', 'id' => 'bundle-a' } }
    let(:bundle_b) { { 'resourceType' => 'Bundle', 'id' => 'bundle-b' } }

    def result_with_input(name, value)
      instance_double(Inferno::Entities::Result, input_json: [{ 'name' => name, 'value' => value }].to_json)
    end

    it 'returns a one-element list for a single bundle object' do
      result = result_with_input('ms_submit_responses', bundle_a.to_json)

      expect(described_class.response_bundles(result, 'submit')).to eq([bundle_a])
    end

    it 'returns all entries for a list of bundle objects' do
      result = result_with_input('ms_submit_responses', [bundle_a, bundle_b].to_json)

      expect(described_class.response_bundles(result, 'submit')).to eq([bundle_a, bundle_b])
    end

    it 'reads the ms_inquire_responses input for the inquire operation' do
      result = result_with_input('ms_inquire_responses', [bundle_b].to_json)

      expect(described_class.response_bundles(result, 'inquire')).to eq([bundle_b])
    end

    it 'returns nil when the input has no value' do
      result = result_with_input('ms_submit_responses', nil)

      expect(described_class.response_bundles(result, 'submit')).to be_nil
    end

    it 'returns nil when the input is not valid JSON' do
      result = result_with_input('ms_submit_responses', 'not json')

      expect(described_class.response_bundles(result, 'submit')).to be_nil
    end

    it 'returns nil when the input contains entries that are not objects' do
      result = result_with_input('ms_submit_responses', [bundle_a, 'not a bundle'].to_json)

      expect(described_class.response_bundles(result, 'submit')).to be_nil
    end
  end
end
