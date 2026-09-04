require_relative '../../../lib/davinci_pas_test_kit/client/user_input_response'

RSpec.describe DaVinciPASTestKit::UserInputResponse do
  describe '.response_candidates' do
    let(:bundle_a) { { 'resourceType' => 'Bundle', 'id' => 'bundle-a' } }
    let(:bundle_b) { { 'resourceType' => 'Bundle', 'id' => 'bundle-b' } }
    let(:wrapped_bundle) { { 'criteria' => { 'requestRange' => '1' }, 'bundle' => bundle_b } }

    let(:configurable) do
      Class.new(Inferno::Entities::Test) do
        input :ms_submit_responses, title: 'Must Support $submit Response Bundles'
        input :ms_inquire_responses, title: 'Must Support $inquire Response Bundles'
      end
    end

    def result_with_input(name, value)
      instance_double(Inferno::Entities::Result, input_json: [{ 'name' => name, 'value' => value }].to_json)
    end

    it 'returns a one-element list for a single bare bundle' do
      result = result_with_input('ms_submit_responses', bundle_a.to_json)

      expect(described_class.response_candidates(configurable, 'submit', result)).to eq([bundle_a])
    end

    it 'returns a one-element list for a single wrapper object' do
      result = result_with_input('ms_submit_responses', wrapped_bundle.to_json)

      expect(described_class.response_candidates(configurable, 'submit', result)).to eq([wrapped_bundle])
    end

    it 'returns all entries for a list mixing bare bundles and wrapper objects' do
      result = result_with_input('ms_submit_responses', [wrapped_bundle, bundle_a].to_json)

      expect(described_class.response_candidates(configurable, 'submit', result)).to eq([wrapped_bundle, bundle_a])
    end

    it 'reads the ms_inquire_responses input for the inquire operation' do
      result = result_with_input('ms_inquire_responses', [bundle_b].to_json)

      expect(described_class.response_candidates(configurable, 'inquire', result)).to eq([bundle_b])
    end

    it 'returns nil when the input has no value' do
      result = result_with_input('ms_submit_responses', nil)

      expect(described_class.response_candidates(configurable, 'submit', result)).to be_nil
    end

    it 'raises an InvalidInputError naming the input by title when it is not valid JSON' do
      result = result_with_input('ms_submit_responses', 'not json')

      expect { described_class.response_candidates(configurable, 'submit', result) }
        .to raise_error(described_class::InvalidInputError,
                        /'Must Support \$submit Response Bundles' input is not valid JSON/)
    end

    it 'raises an InvalidInputError naming the entry number when an entry is not an object' do
      result = result_with_input('ms_submit_responses', [bundle_a, 'not a bundle'].to_json)

      expect { described_class.response_candidates(configurable, 'submit', result) }
        .to raise_error(described_class::InvalidInputError,
                        /Entry 2 of the 'Must Support \$submit Response Bundles' input/)
    end

    it 'raises an InvalidInputError when a wrapper is missing its bundle' do
      result = result_with_input('ms_submit_responses', [{ 'criteria' => { 'requestRange' => '1' } }].to_json)

      expect { described_class.response_candidates(configurable, 'submit', result) }
        .to raise_error(described_class::InvalidInputError,
                        /Entry 1 .*neither a FHIR Bundle nor a wrapper object with a FHIR Bundle in the "bundle" key\./)
    end

    it 'falls back to the input name when the configurable does not define a title' do
      untitled = Class.new(Inferno::Entities::Test) { input :ms_inquire_responses }
      result = result_with_input('ms_inquire_responses', 'not json')

      expect { described_class.response_candidates(untitled, 'inquire', result) }
        .to raise_error(described_class::InvalidInputError, /'ms_inquire_responses' input is not valid JSON/)
    end
  end
end
