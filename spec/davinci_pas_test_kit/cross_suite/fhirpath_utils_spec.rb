require_relative '../../../lib/davinci_pas_test_kit/cross_suite/fhirpath_utils'

RSpec.describe DaVinciPASTestKit::FhirpathUtils do
  let(:utils) { Class.new { include DaVinciPASTestKit::FhirpathUtils }.new }
  let(:request_bundle) { FHIR::Bundle.new(id: 'example-request') }

  def stub_fhirpath_service(expression, results, status: 200)
    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate")
      .with(query: { 'path' => expression })
      .to_return(status:, body: results.is_a?(String) ? results : results.to_json)
  end

  def fhirpath_response(body)
    instance_double(Faraday::Response, body:)
  end

  describe '#execute_fhirpath' do
    it 'returns the service response for a successful evaluation' do
      stub = stub_fhirpath_service('Bundle.id', [{ type: 'string', element: 'example-request' }])

      response = utils.execute_fhirpath(request_bundle, 'Bundle.id')

      expect(response.status).to eq(200)
      expect(stub).to have_been_requested
    end

    it 'raises FhirpathServiceError when the service returns an error' do
      stub_fhirpath_service('Bundle.id', 'internal error', status: 500)

      expect { utils.execute_fhirpath(request_bundle, 'Bundle.id') }
        .to raise_error(DaVinciPASTestKit::FhirpathUtils::FhirpathServiceError, /500/)
    end
  end

  describe '#interpret_fhirpath_result_as_boolean' do
    it 'returns the element value for a single boolean result' do
      expect(utils.interpret_fhirpath_result_as_boolean(fhirpath_response([{ type: 'boolean',
                                                                             element: true }].to_json))).to be(true)
      expect(utils.interpret_fhirpath_result_as_boolean(fhirpath_response([{ type: 'boolean',
                                                                             element: false }].to_json))).to be(false)
    end

    it 'returns true for a single non-boolean result' do
      result = fhirpath_response([{ type: 'string', element: 'value' }].to_json)
      expect(utils.interpret_fhirpath_result_as_boolean(result)).to be(true)
    end

    it 'returns false for an empty result' do
      expect(utils.interpret_fhirpath_result_as_boolean(fhirpath_response([].to_json))).to be(false)
    end

    it 'returns false for multiple results' do
      result = fhirpath_response([{ type: 'string', element: 'a' }, { type: 'string', element: 'b' }].to_json)
      expect(utils.interpret_fhirpath_result_as_boolean(result)).to be(false)
    end

    it 'returns false for an unparseable body' do
      expect(utils.interpret_fhirpath_result_as_boolean(fhirpath_response('not json'))).to be(false)
    end
  end

  describe '#replace_tokens_in_string' do
    it 'returns the string unchanged when it contains no tokens' do
      expect(utils.replace_tokens_in_string('{"id":"static"}', request_bundle)).to eq('{"id":"static"}')
      expect(a_request(:post, %r{/evaluate})).to_not have_been_made
    end

    it 'replaces each token with the fhirpath result evaluated against the request' do
      stub_fhirpath_service('Bundle.id', [{ type: 'string', element: 'example-request' }])

      replaced = utils.replace_tokens_in_string('{"id":"{{Bundle.id}}"}', request_bundle)

      expect(replaced).to eq('{"id":"example-request"}')
    end

    it 'evaluates repeated tokens only once' do
      stub = stub_fhirpath_service('Bundle.id', [{ type: 'string', element: 'example-request' }])

      replaced = utils.replace_tokens_in_string('{{Bundle.id}} and {{Bundle.id}}', request_bundle)

      expect(replaced).to eq('example-request and example-request')
      expect(stub).to have_been_requested.once
    end

    it 'joins multiple primitive results with commas and drops complex results' do
      stub_fhirpath_service('Bundle.entry.resource.id',
                            [{ type: 'string', element: 'a' },
                             { type: 'BackboneElement', element: { 'key' => 'value' } },
                             { type: 'string', element: 'b' }])

      replaced = utils.replace_tokens_in_string('{{Bundle.entry.resource.id}}', request_bundle)

      expect(replaced).to eq('a,b')
    end
  end
end
