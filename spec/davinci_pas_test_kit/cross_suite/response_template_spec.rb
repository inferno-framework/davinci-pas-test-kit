require_relative '../../../lib/davinci_pas_test_kit/cross_suite/response_template'

RSpec.describe DaVinciPASTestKit::ResponseTemplate do
  let(:request_bundle) { FHIR::Bundle.new(id: 'example-request') }
  let(:results) { {} }
  # Results are given as elements, or as typed(...) for results whose FHIR type matters
  let(:evaluator) do
    expressions = results
    Class.new do
      define_method(:evaluate_fhirpath_results) do |_resource, expression|
        raise "unexpected expression: #{expression}" unless expressions.key?(expression)

        expressions[expression].map do |result|
          next result.transform_keys(&:to_s) if result.is_a?(Hash) && result.key?(:type)

          { 'type' => 'test', 'element' => result }
        end
      end
    end.new
  end

  def typed(type, element)
    { type:, element: }
  end

  def instantiate(template)
    described_class.new(request_bundle, evaluator).instantiate(template)
  end

  describe 'tokens within longer strings' do
    it 'joins primitive results with commas and drops complex results' do
      results['Bundle.entry.resource.id'] = ['a', { 'key' => 'value' }, 2, true]

      expect(instantiate('text' => 'ids: {{Bundle.entry.resource.id}}.'))
        .to eq('text' => 'ids: a,2,true.')
    end

    it 'leaves strings without tokens unchanged' do
      expect(instantiate('id' => 'static', 'count' => 1)).to eq('id' => 'static', 'count' => 1)
    end
  end

  describe 'whole-value tokens' do
    it 'inserts single results with their type' do
      results['Bundle.id'] = ['example-request']
      results['Bundle.total'] = [2]
      results['Bundle.exists()'] = [true]
      results['Bundle.identifier'] = [{ 'value' => 'abc' }]

      template = { 'id' => '{{Bundle.id}}', 'total' => '{{Bundle.total}}', 'flag' => '{{Bundle.exists()}}',
                   'identifier' => '{{Bundle.identifier}}' }

      expect(instantiate(template)).to eq('id' => 'example-request', 'total' => 2, 'flag' => true,
                                          'identifier' => { 'value' => 'abc' })
    end

    it 'turns several results for an object element into an array' do
      results['Bundle.entry.fullUrl'] = %w[a b]

      expect(instantiate('urls' => '{{Bundle.entry.fullUrl}}')).to eq('urls' => %w[a b])
    end

    it 'removes object elements with no results' do
      results['Bundle.nothing'] = []

      expect(instantiate('id' => 'kept', 'missing' => '{{Bundle.nothing}}')).to eq('id' => 'kept')
    end

    it 'splices every result into an array in place of the token' do
      results['Bundle.entry'] = [{ 'fullUrl' => 'a' }, { 'fullUrl' => 'b' }]
      results['Bundle.nothing'] = []

      template = { 'entry' => [{ 'fullUrl' => 'first' }, '{{Bundle.entry}}', '{{Bundle.nothing}}', 'last'] }

      expect(instantiate(template))
        .to eq('entry' => [{ 'fullUrl' => 'first' }, { 'fullUrl' => 'a' }, { 'fullUrl' => 'b' }, 'last'])
    end

    it 'removes arrays left empty' do
      results['Bundle.nothing'] = []

      expect(instantiate('id' => 'kept', 'entry' => ['{{Bundle.nothing}}'])).to eq('id' => 'kept')
    end

    it 'removes custom extensions from copied data types but not from resources or entries' do
      custom = { 'url' => 'http://example.org/custom', 'valueString' => 'x' }
      hl7 = { 'url' => 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-x', 'valueString' => 'y' }
      results['identifier'] = [{ 'extension' => [custom, hl7], 'value' => '1',
                                 'assigner' => { 'extension' => [custom], 'display' => 'z' } }]
      results['resource'] = [{ 'resourceType' => 'Patient', 'extension' => [custom] }]
      entry = { 'fullUrl' => 'a', 'resource' => { 'resourceType' => 'Patient', 'extension' => [custom] } }
      results['entry'] = [typed('Bundle.entry', entry)]
      parameter = { 'name' => 'p', 'resource' => { 'resourceType' => 'Patient' }, 'extension' => [custom] }
      results['parameter'] = [typed('Parameters.parameter', parameter)]

      instantiated = instantiate('identifier' => ['{{identifier}}'], 'contained' => ['{{resource}}'],
                                 'entry' => ['{{entry}}'], 'parameter' => ['{{parameter}}'])

      expect(instantiated['identifier']).to eq([{ 'extension' => [hl7], 'value' => '1',
                                                  'assigner' => { 'display' => 'z' } }])
      expect(instantiated['contained']).to eq(results['resource'])
      expect(instantiated['entry']).to eq([entry])
      expect(instantiated['parameter']).to eq([parameter.except('extension')])
    end

    it 'copies only HL7 extensions when extensions themselves are copied' do
      custom = { 'url' => 'http://example.org/custom', 'valueString' => 'x' }
      hl7 = { 'url' => 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-x', 'valueString' => 'y' }
      results['Bundle.entry.resource.ofType(Claim).extension'] = [typed('Extension', custom), typed('Extension', hl7)]

      expect(instantiate('extension' => ['{{Bundle.entry.resource.ofType(Claim).extension}}']))
        .to eq('extension' => [hl7])
    end

    it 'evaluates each expression once' do
      calls = Hash.new(0)
      counting_evaluator = Class.new do
        define_method(:evaluate_fhirpath_results) do |_resource, expression|
          calls[expression] += 1
          [{ 'type' => 'string', 'element' => 'value' }]
        end
      end.new

      described_class.new(request_bundle, counting_evaluator)
        .instantiate('a' => '{{Bundle.id}}', 'b' => ['{{Bundle.id}}'], 'c' => 'x {{Bundle.id}}')

      expect(calls).to eq('Bundle.id' => 1)
    end
  end

  describe '$forEach objects' do
    let(:items) { 'Bundle.entry.resource.ofType(Claim).item' }

    it 'splices a copy of the template into an array for each result, with %current referring to it' do
      results[items] = [{ 'sequence' => 1 }, { 'sequence' => 2 }]
      results["(#{items})[0].sequence"] = [1]
      results["(#{items})[1].sequence"] = [2]

      template = { 'item' => [{ '$forEach' => items,
                                'template' => { 'itemSequence' => '{{%current.sequence}}', 'note' => 'static' } }] }

      expect(instantiate(template)).to eq('item' => [{ 'itemSequence' => 1, 'note' => 'static' },
                                                     { 'itemSequence' => 2, 'note' => 'static' }])
    end

    it 'always produces an array for an object element' do
      results[items] = [{ 'sequence' => 1 }]

      expect(instantiate('item' => { '$forEach' => items, 'template' => { 'a' => 'b' } }))
        .to eq('item' => [{ 'a' => 'b' }])
    end

    it 'removes the element when there are no results' do
      results[items] = []

      expect(instantiate('id' => 'kept', 'item' => [{ '$forEach' => items, 'template' => { 'a' => 'b' } }]))
        .to eq('id' => 'kept')
    end

    it 'scopes %current to the innermost $forEach' do
      results[items] = [{}]
      results["(#{items})[0].detail"] = [{}, {}]
      results["((#{items})[0].detail)[0].sequence"] = [11]
      results["((#{items})[0].detail)[1].sequence"] = [12]
      results["(#{items})[0].sequence"] = [1]

      template = {
        'item' => [{
          '$forEach' => items,
          'template' => {
            'itemSequence' => '{{%current.sequence}}',
            'detail' => [{ '$forEach' => '%current.detail',
                           'template' => { 'detailSequence' => '{{%current.sequence}}' } }]
          }
        }]
      }

      expect(instantiate(template)).to eq(
        'item' => [{ 'itemSequence' => 1, 'detail' => [{ 'detailSequence' => 11 }, { 'detailSequence' => 12 }] }]
      )
    end

    it 'makes a copy for each result, including results without a value' do
      results[items] = [nil, { 'sequence' => 2 }]
      results["(#{items})[0].sequence"] = []
      results["(#{items})[1].sequence"] = [2]

      expect(instantiate('item' => [{ '$forEach' => items, 'template' => { 'n' => '{{%current.sequence}}' } }]))
        .to eq('item' => [{}, { 'n' => 2 }])
    end

    it 'keeps backslashes and quotes in the expression when replacing %current' do
      expression = "Bundle.entry.where(fullUrl.matches('\\\\d') or fullUrl = 'O\\'Brien')"
      results[expression] = [{}]
      results["(#{expression})[0].id"] = ['found']

      expect(instantiate('ids' => [{ '$forEach' => expression, 'template' => '{{%current.id}}' }]))
        .to eq('ids' => ['found'])
    end

    it 'raises a TemplateError for an array template' do
      expect { instantiate('item' => [{ '$forEach' => items, 'template' => [1, 2] }]) }
        .to raise_error(described_class::TemplateError, /must not be an array/)
    end

    it 'raises a TemplateError for a $forEach object without exactly an expression and a template' do
      expect { instantiate('item' => [{ '$forEach' => items, 'other' => {} }]) }
        .to raise_error(described_class::TemplateError, /must contain only.*found keys "\$forEach", "other"/)
      expect { instantiate('item' => [{ '$forEach' => '', 'template' => {} }]) }
        .to raise_error(described_class::TemplateError, /must contain only/)
    end

    it 'raises a TemplateError for %current outside of a $forEach template' do
      expect { instantiate('id' => '{{%current.id}}') }
        .to raise_error(described_class::TemplateError, /uses %current outside of a "\$forEach" template/)
    end
  end

  it 'raises a TemplateError when the template is not an object' do
    expect { described_class.new(request_bundle, evaluator).instantiate([]) }
      .to raise_error(described_class::TemplateError, /must be a JSON object/)
  end

  describe '.template?' do
    it 'detects tokens and $forEach objects' do
      expect(described_class.template?('{"id":"{{Bundle.id}}"}')).to be(true)
      expect(described_class.template?('{"item":[{"$forEach":"x","template":{}}]}')).to be(true)
      expect(described_class.template?('{"id":"static"}')).to be(false)
    end
  end
end
