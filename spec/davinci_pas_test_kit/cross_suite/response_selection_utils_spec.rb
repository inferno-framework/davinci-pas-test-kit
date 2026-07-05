require_relative '../../../lib/davinci_pas_test_kit/cross_suite/response_selection_utils'

RSpec.describe DaVinciPASTestKit::ResponseSelectionUtils do
  let(:utils_class) do
    Class.new do
      include DaVinciPASTestKit::FhirpathUtils
      include DaVinciPASTestKit::ResponseSelectionUtils

      attr_accessor :result
    end
  end
  let(:result) { instance_double(Inferno::Entities::Result, id: 'test-result-id') }
  let(:utils) do
    instance = utils_class.new
    instance.result = result
    instance
  end
  let(:request_bundle) { FHIR::Bundle.new(id: 'example-request') }

  def range_extension(range)
    { 'url' => described_class::REQUEST_RANGE_EXTENSION_URL, 'valueString' => range }
  end

  def inclusion_extension(expression)
    { 'url' => described_class::INCLUSION_CRITERIA_EXTENSION_URL, 'valueExpression' => { 'expression' => expression } }
  end

  def stub_previous_requests(*requests)
    requests_repo = instance_double(Inferno::Repositories::Requests, requests_for_result: requests)
    allow(Inferno::Repositories::Requests).to receive(:new).and_return(requests_repo)
  end

  def previous_request(url, status = 200)
    instance_double(Inferno::Entities::Request, url:, status:)
  end

  def stub_fhirpath_service(expression, results)
    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
      .with(query: { 'path' => expression })
      .to_return(status: 200, body: results.to_json)
  end

  describe '#include_entity?' do
    it 'includes an entity with no criteria extensions' do
      expect(utils.include_entity?({ 'resourceType' => 'Bundle' }, request_bundle, '$submit')).to be(true)
    end

    it 'includes an entity whose request range covers the current request number' do
      stub_previous_requests

      entity = { 'extension' => [range_extension('1')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(true)
    end

    it 'excludes an entity whose request range does not cover the current request number' do
      stub_previous_requests

      entity = { 'extension' => [range_extension('2-3')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(false)
    end

    it 'counts only previous successful requests to the same operation' do
      stub_previous_requests(
        previous_request('https://inferno.test/custom/suite/fhir/Claim/$submit'),
        previous_request('https://inferno.test/custom/suite/fhir/Claim/$submit', 400),
        previous_request('https://inferno.test/custom/suite/fhir/Claim/$inquire')
      )

      entity = { 'extension' => [range_extension('2')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(true)
    end

    it 'includes an entity whose inclusion criteria evaluate to true against the request' do
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: true }])

      entity = { 'extension' => [inclusion_extension('Bundle.id.exists()')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(true)
    end

    it 'excludes an entity whose inclusion criteria evaluate to false against the request' do
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: false }])

      entity = { 'extension' => [inclusion_extension('Bundle.id.exists()')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(false)
    end

    it 'excludes an entity whose inclusion criteria return no results' do
      stub_fhirpath_service('Bundle.wrong', [])

      entity = { 'extension' => [inclusion_extension('Bundle.wrong')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(false)
    end

    it 'requires both criteria to be met when both are present' do
      stub_previous_requests
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: false }])

      entity = { 'extension' => [range_extension('1'), inclusion_extension('Bundle.id.exists()')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(false)
    end

    it 'includes an entity when both criteria are met' do
      stub_previous_requests
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: true }])

      entity = { 'extension' => [range_extension('1'), inclusion_extension('Bundle.id.exists()')] }

      expect(utils.include_entity?(entity, request_bundle, '$submit')).to be(true)
    end
  end

  describe '#ranges_cover_value?' do
    it 'supports comma-separated single values and ranges' do
      expect(utils.ranges_cover_value?(1, '1-2,4')).to be(true)
      expect(utils.ranges_cover_value?(3, '1-2,4')).to be(false)
      expect(utils.ranges_cover_value?(4, '1-2,4')).to be(true)
    end

    it 'raises a TestSuiteImplementationException for an invalid range string' do
      expect { utils.ranges_cover_value?(1, 'one') }
        .to raise_error(Inferno::Exceptions::TestSuiteImplementationException, /Invalid range string/)
    end

    it 'raises a TestSuiteImplementationException for an inverted range' do
      expect { utils.ranges_cover_value?(1, '3-2') }
        .to raise_error(Inferno::Exceptions::TestSuiteImplementationException, /Inverted range/)
    end
  end

  describe '#strip_inferno_extensions' do
    it 'removes Inferno selection criteria extensions and keeps others' do
      other_extension = { 'url' => 'http://example.com/other', 'valueString' => 'keep' }
      entity = { 'resourceType' => 'Bundle',
                 'extension' => [range_extension('1'), other_extension, inclusion_extension('Bundle.id.exists()')] }

      expect(utils.strip_inferno_extensions(entity)['extension']).to eq([other_extension])
    end

    it 'removes the extension element entirely when only Inferno extensions are present' do
      entity = { 'resourceType' => 'Bundle', 'extension' => [range_extension('1')] }

      expect(utils.strip_inferno_extensions(entity)).to_not have_key('extension')
    end

    it 'leaves an entity without extensions unchanged' do
      entity = { 'resourceType' => 'Bundle' }

      expect(utils.strip_inferno_extensions(entity)).to eq({ 'resourceType' => 'Bundle' })
    end
  end
end
