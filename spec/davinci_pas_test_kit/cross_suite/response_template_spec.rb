require_relative '../../../lib/davinci_pas_test_kit/cross_suite/response_template'

RSpec.describe DaVinciPASTestKit::ResponseTemplate do
  let(:request_bundle) { FHIR::Bundle.new(id: 'example-request') }
  let(:results) { {} }
  let(:evaluator) do
    expressions = results
    Class.new do
      define_method(:evaluate_fhirpath_elements) do |_resource, expression|
        raise "unexpected expression: #{expression}" unless expressions.key?(expression)

        expressions[expression]
      end
    end.new
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
      results['entry'] = [{ 'fullUrl' => 'a', 'resource' => { 'resourceType' => 'Patient', 'extension' => [custom] } }]

      instantiated = instantiate('identifier' => ['{{identifier}}'], 'contained' => ['{{resource}}'],
                                 'entry' => ['{{entry}}'])

      expect(instantiated['identifier']).to eq([{ 'extension' => [hl7], 'value' => '1',
                                                  'assigner' => { 'display' => 'z' } }])
      expect(instantiated['contained']).to eq(results['resource'])
      expect(instantiated['entry']).to eq(results['entry'])
    end

    it 'evaluates each expression once' do
      calls = Hash.new(0)
      counting_evaluator = Class.new do
        define_method(:evaluate_fhirpath_elements) do |_resource, expression|
          calls[expression] += 1
          ['value']
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
