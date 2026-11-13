require_relative '../../../lib/davinci_pas_test_kit/client/pended_response_detection'

RSpec.describe DaVinciPASTestKit::PendedResponseDetection do
  def review_action(code)
    { 'url' => described_class::REVIEW_ACTION_URL,
      'extension' => [{ 'url' => described_class::REVIEW_ACTION_CODE_URL,
                        'valueCodeableConcept' => { 'coding' => [{ 'code' => code }] } }] }
  end

  def response_bundle(*codes)
    items = codes.map { |code| { 'adjudication' => [{ 'extension' => [review_action(code)] }] } }
    { 'resourceType' => 'Bundle', 'type' => 'collection',
      'entry' => [{ 'resource' => { 'resourceType' => 'ClaimResponse', 'item' => items } }] }
  end

  it 'identifies a response with an item adjudication pended with review action code A4' do
    expect(described_class.pended?(response_bundle('A1', 'A4'))).to be(true)
  end

  it 'accepts the response as JSON' do
    expect(described_class.pended?(response_bundle('A4').to_json)).to be(true)
  end

  it 'identifies a pended response template that repeats items with $forEach' do
    templates_dir = File.join(__dir__, '../../fixtures/response_templates')
    template = JSON.parse(File.read(File.join(templates_dir, 'submit_pended_v2.2.1.json')))
    approval = JSON.parse(File.read(File.join(templates_dir, 'submit_approval_v2.2.1.json')))

    expect(described_class.pended?(template)).to be(true)
    expect(described_class.pended?(approval)).to be(false)
  end

  it 'does not identify a response without the pended review action code' do
    expect(described_class.pended?(response_bundle('A1', 'A3'))).to be(false)
  end

  it 'identifies the pended response in Inferno\'s mocked v2.2.1 responses' do
    generator = Class.new { include DaVinciPASTestKit::ResponseGenerator }.new
    request_bundle = FHIR.from_contents(
      File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
    )

    pended = generator.mock_response_bundle(request_bundle, 'submit', :pended, nil, 'v2.2.1')
    approved = generator.mock_response_bundle(request_bundle, 'submit', :approval, nil, 'v2.2.1')

    expect(described_class.pended?(pended)).to be(true)
    expect(described_class.pended?(approved)).to be(false)
  end

  it 'treats content that is not a Bundle, or is malformed, as not pended' do
    malformed = { 'resourceType' => 'Bundle', 'entry' => [{ 'resource' => { 'resourceType' => 'ClaimResponse',
                                                                            'item' => 'not a list' } }, 'x'] }

    expect(described_class.pended?(malformed)).to be(false)
    expect(described_class.pended?({ 'resourceType' => 'Parameters' })).to be(false)
    expect(described_class.pended?('not json')).to be(false)
    expect(described_class.pended?(nil)).to be(false)
  end
end
