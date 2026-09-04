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
  let(:inner_bundle) { { 'resourceType' => 'Bundle', 'id' => 'inner' } }

  def wrapper(criteria = nil)
    { 'criteria' => criteria, 'bundle' => inner_bundle }.compact
  end

  def stub_previous_requests(*requests)
    requests_repo = instance_double(Inferno::Repositories::Requests, requests_for_result: requests)
    allow(Inferno::Repositories::Requests).to receive(:new).and_return(requests_repo)
  end

  def previous_request(url, status = 200)
    instance_double(Inferno::Entities::Request, url:, status:)
  end

  def stub_result_messages(*existing_messages)
    existing = existing_messages.map { |message| instance_double(Inferno::Entities::Message, message:) }
    messages_repo = instance_double(Inferno::Repositories::Messages, messages_for_result: existing, create: nil)
    allow(Inferno::Repositories::Messages).to receive(:new).and_return(messages_repo)
    messages_repo
  end

  def stub_fhirpath_service(expression, results)
    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
      .with(query: { 'path' => expression })
      .to_return(status: 200, body: results.to_json)
  end

  describe '#include_entity?' do
    it 'includes a bare bundle' do
      expect(utils.include_entity?(inner_bundle, request_bundle, 1)).to be(true)
    end

    it 'includes a wrapper with no criteria' do
      expect(utils.include_entity?(wrapper, request_bundle, 1)).to be(true)
    end

    it 'includes a wrapper whose request range covers the current request number' do
      entity = wrapper({ 'requestRange' => '1' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(true)
    end

    it 'excludes a wrapper whose request range does not cover the current request number' do
      entity = wrapper({ 'requestRange' => '2-3' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(false)
    end

    it 'accepts a request range given as a number' do
      entity = wrapper({ 'requestRange' => 1 })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(true)
    end

    it 'excludes a wrapper with an invalid request range instead of raising' do
      stub_result_messages
      entity = wrapper({ 'requestRange' => '1-2,a' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(false)
    end

    it 'includes a wrapper whose fhirpath criteria evaluate to true against the request' do
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: true }])

      entity = wrapper({ 'fhirpath' => 'Bundle.id.exists()' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(true)
    end

    it 'excludes a wrapper whose fhirpath criteria evaluate to false against the request' do
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: false }])

      entity = wrapper({ 'fhirpath' => 'Bundle.id.exists()' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(false)
    end

    it 'excludes a wrapper whose fhirpath criteria return no results' do
      stub_fhirpath_service('Bundle.wrong', [])

      entity = wrapper({ 'fhirpath' => 'Bundle.wrong' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(false)
    end

    it 'requires both criteria to be met when both are present' do
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: false }])

      entity = wrapper({ 'requestRange' => '1', 'fhirpath' => 'Bundle.id.exists()' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(false)
    end

    it 'includes a wrapper when both criteria are met' do
      stub_fhirpath_service('Bundle.id.exists()', [{ type: 'boolean', element: true }])

      entity = wrapper({ 'requestRange' => '1', 'fhirpath' => 'Bundle.id.exists()' })

      expect(utils.include_entity?(entity, request_bundle, 1)).to be(true)
    end
  end

  describe '#entity_bundle' do
    it 'returns a bare bundle unchanged' do
      expect(utils.entity_bundle(inner_bundle)).to eq(inner_bundle)
    end

    it 'returns the inner bundle of a wrapper' do
      expect(utils.entity_bundle(wrapper({ 'requestRange' => '1' }))).to eq(inner_bundle)
    end
  end

  describe '#entity_criteria' do
    it 'returns no criteria for a bare bundle' do
      expect(utils.entity_criteria(inner_bundle)).to eq({})
    end

    it 'returns no criteria for a wrapper without them' do
      expect(utils.entity_criteria(wrapper)).to eq({})
    end

    it 'returns the criteria of a wrapper' do
      expect(utils.entity_criteria(wrapper({ 'requestRange' => '1' }))).to eq({ 'requestRange' => '1' })
    end
  end

  describe '#count_previous_successful_requests' do
    it 'counts only successful requests to the given operation' do
      stub_previous_requests(
        previous_request('https://inferno.test/custom/suite/fhir/Claim/$submit'),
        previous_request('https://inferno.test/custom/suite/fhir/Claim/$submit', 400),
        previous_request('https://inferno.test/custom/suite/fhir/Claim/$inquire')
      )

      expect(utils.count_previous_successful_requests('$submit')).to eq(1)
    end
  end

  describe '#ranges_cover_value?' do
    it 'supports comma-separated single values and ranges' do
      expect(utils.ranges_cover_value?(1, '1-2,4')).to be(true)
      expect(utils.ranges_cover_value?(3, '1-2,4')).to be(false)
      expect(utils.ranges_cover_value?(4, '1-2,4')).to be(true)
    end

    it 'warns on the test and returns false for an invalid range string' do
      messages_repo = stub_result_messages

      expect(utils.ranges_cover_value?(1, 'one')).to be(false)
      expect(messages_repo).to have_received(:create).with(
        result_id: 'test-result-id',
        type: 'warning',
        message: a_string_matching(/Invalid requestRange criteria "one"\. The corresponding Bundle was not selected/)
      )
    end

    it 'warns on the test and returns false for an inverted range' do
      messages_repo = stub_result_messages

      expect(utils.ranges_cover_value?(1, '3-2')).to be(false)
      expect(messages_repo).to have_received(:create).with(
        result_id: 'test-result-id',
        type: 'warning',
        message: a_string_matching(/Invalid requestRange criteria "3-2".*\("3-2" is inverted\)/)
      )
    end
  end

  describe '#add_result_warning' do
    it 'records a warning on the result' do
      messages_repo = stub_result_messages

      utils.add_result_warning('something went wrong')

      expect(messages_repo).to have_received(:create)
        .with(result_id: 'test-result-id', type: 'warning', message: 'something went wrong')
    end

    it 'does not record a warning that the result already has' do
      messages_repo = stub_result_messages('something went wrong')

      utils.add_result_warning('something went wrong')

      expect(messages_repo).to_not have_received(:create)
    end
  end
end
